const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fetch = require('node-fetch');

admin.initializeApp();
const db = admin.firestore();

// ── Gemini API Config ───────────────────────────────────────────────────────
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || "AIzaSyAYsBeiGlp1tXaRodw249qq8bZrzyPD8cQ";
const GEMINI_MODEL = "gemini-2.0-flash";
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

/**
 * Helper: Call Gemini API
 */
async function callGemini(prompt) {
    const response = await fetch(GEMINI_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
                temperature: 0.7,
                maxOutputTokens: 1024,
            },
        }),
    });

    const data = await response.json();
    return data?.candidates?.[0]?.content?.parts?.[0]?.text || null;
}

/**
 * Helper: Fetch transporter data from Firestore
 */
async function getTransporterData(transporterId) {
    const userDoc = await db.collection('users').doc(transporterId).get();
    if (!userDoc.exists) return null;

    const userData = userDoc.data();

    // Also get shipment stats
    const shipmentsSnap = await db.collection('shipments')
        .where('transporterId', '==', transporterId)
        .get();

    let totalShipments = 0;
    let fraudFlags = [];
    let delayedCount = 0;
    let deliveredCount = 0;

    shipmentsSnap.forEach(doc => {
        const s = doc.data();
        totalShipments++;
        if (s.status === 'delivered') deliveredCount++;
        if (s.status === 'delayed') delayedCount++;
        if (s.fraudFlags && Array.isArray(s.fraudFlags)) {
            fraudFlags = fraudFlags.concat(s.fraudFlags);
        }
    });

    return {
        ...userData,
        totalShipments,
        deliveredCount,
        delayedCount,
        fraudFlags,
    };
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. TRUST SCORE CALCULATOR (Firestore Trigger — unchanged logic)
// ═══════════════════════════════════════════════════════════════════════════════
exports.calculateTrustScore = functions.firestore
    .document('shipments/{shipmentId}')
    .onWrite(async (change, context) => {
        const data = change.after.exists ? change.after.data() : change.before.data();
        const transporterId = data.transporterId;

        if (!transporterId) {
            console.log('No transporter assigned, skipping.');
            return null;
        }

        console.log(`Calculating trust score for transporter: ${transporterId}`);

        const shipmentsSnapshot = await db.collection('shipments').where('transporterId', '==', transporterId).get();
        const userRef = db.collection('users').doc(transporterId);

        let totalShipments = 0;
        let completedDeliveries = 0;
        let onTimeDeliveries = 0;
        let shipmentsWithProof = 0;
        let cancelledShipments = 0;
        let totalGpsUpdates = 0;
        const EXPECTED_UPDATES_PER_TRIP = 10;
        let expectedGpsUpdates = 0;

        shipmentsSnapshot.forEach(doc => {
            const shipment = doc.data();
            totalShipments++;

            if (shipment.status === 'delivered') {
                completedDeliveries++;
                if (!shipment.delayInMinutes || shipment.delayInMinutes <= 0) {
                    onTimeDeliveries++;
                }
            }

            if (shipment.status === 'cancelled' || shipment.cancellationFlag === true) {
                cancelledShipments++;
            }

            if (shipment.epodUrl || shipment.proofUploaded === true) {
                shipmentsWithProof++;
            }

            if (shipment.gpsUpdatesCount > 0) {
                totalGpsUpdates += shipment.gpsUpdatesCount;
            }
            if (shipment.status === 'in_transit' || shipment.status === 'delivered') {
                expectedGpsUpdates += EXPECTED_UPDATES_PER_TRIP;
            }
        });

        if (totalShipments === 0) return null;

        const userDoc = await userRef.get();
        let avgRating = 5.0;
        if (userDoc.exists && userDoc.data().avgRating !== undefined) {
            avgRating = userDoc.data().avgRating;
        }

        const onTimeRate = completedDeliveries > 0 ? (onTimeDeliveries / completedDeliveries) : 1;
        const proofRate = totalShipments > 0 ? (shipmentsWithProof / totalShipments) : 1;
        const gpsScore = expectedGpsUpdates > 0 ? Math.min(totalGpsUpdates / expectedGpsUpdates, 1) : (totalGpsUpdates > 0 ? 1 : 0);
        const cancelPenalty = totalShipments > 0 ? (cancelledShipments / totalShipments) : 0;

        const weightOnTime = onTimeRate * 40;
        const weightProof = proofRate * 20;
        const weightGps = gpsScore * 15;
        const weightCancel = (1 - cancelPenalty) * 15;
        const weightRating = (avgRating / 5.0) * 10;

        let finalScore = weightOnTime + weightProof + weightGps + weightCancel + weightRating;
        finalScore = Math.max(0, Math.min(100, finalScore));

        const trustBreakdown = {
            onTimeRate, proofRate, gpsScore, cancelPenalty, avgRating,
            breakdownPct: { onTime: weightOnTime, proof: weightProof, gps: weightGps, cancel: weightCancel, rating: weightRating }
        };

        console.log(`Final trust score for ${transporterId}: ${finalScore}`);

        await userRef.set({
            trustScore: finalScore,
            totalShipments,
            completedTrips: completedDeliveries,
            cancelledShipments,
            onTimeRate: onTimeRate * 100,
            epodComplianceRate: proofRate * 100,
            gpsReliability: gpsScore * 100,
            trustBreakdown,
            avgRating,
        }, { merge: true });

        return { success: true, trustScore: finalScore };
    });

// ═══════════════════════════════════════════════════════════════════════════════
// 2. AUTO TRUST REPORT (Firestore Trigger — generates when trust score changes)
// ═══════════════════════════════════════════════════════════════════════════════
exports.generateTrustReport = functions.firestore
    .document('users/{userId}')
    .onUpdate(async (change, context) => {
        const afterData = change.after.data();

        if (afterData.role !== 'transporter') return null;
        if (change.before.data().trustScore === afterData.trustScore) return null;

        const prompt = `
You are an AI logistics analyst for TrustNet AI platform.
Analyze this transporter and generate a professional trust assessment.

TRANSPORTER DATA:
- Trust Score: ${afterData.trustScore?.toFixed?.(1) || afterData.trustScore || 0}/100
- On-time Rate: ${afterData.onTimeRate?.toFixed?.(1) || afterData.onTimeRate || 0}%
- ePOD Compliance: ${afterData.epodComplianceRate?.toFixed?.(1) || afterData.epodComplianceRate || 0}%
- GPS Reliability: ${afterData.gpsReliability?.toFixed?.(1) || afterData.gpsReliability || 0}%
- Cancellation Rate: ${afterData.cancelledShipments || 0} out of ${afterData.totalShipments || 0}
- Average Rating: ${afterData.avgRating || 0}/5.0
- Total Shipments: ${afterData.totalShipments || 0}

Generate a report with these sections (use plain text, no markdown):
1. OVERALL ASSESSMENT (2-3 sentences)
2. STRENGTHS (bullet points)
3. RISK FACTORS (any concerns)
4. RECOMMENDATION (shipment suitability)
5. SUGGESTED ACTIONS (improvement tips)

Be specific and data-driven.
`;

        try {
            const aiText = await callGemini(prompt);
            if (aiText) {
                await db.collection('users').doc(context.params.userId).update({
                    aiReport: aiText,
                    aiUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        } catch (e) {
            console.error('Error generating trust report:', e);
        }

        return null;
    });

// ═══════════════════════════════════════════════════════════════════════════════
// 3. ON-DEMAND AI REPORT (Callable — Flutter calls this)
// ═══════════════════════════════════════════════════════════════════════════════
exports.generateAIReport = functions.https.onCall(async (data, context) => {
    const { type, transporterId } = data;

    if (!transporterId) {
        throw new functions.https.HttpsError('invalid-argument', 'transporterId is required');
    }

    if (!type || !['trust_report', 'fraud_analysis', 'delivery_prediction'].includes(type)) {
        throw new functions.https.HttpsError('invalid-argument', 'type must be trust_report, fraud_analysis, or delivery_prediction');
    }

    // Fetch real transporter data
    const tData = await getTransporterData(transporterId);
    if (!tData) {
        throw new functions.https.HttpsError('not-found', 'Transporter not found');
    }

    let prompt;
    let firestoreField;

    switch (type) {
        case 'trust_report':
            firestoreField = 'aiReport';
            prompt = `
You are an AI logistics analyst for TrustNet AI, an intelligent logistics trust platform.
Analyze this transporter and generate a professional trust assessment report.

REAL TRANSPORTER DATA:
- Trust Score: ${tData.trustScore || 0}/100
- On-time Delivery Rate: ${tData.onTimeRate || 0}%
- ePOD Compliance Rate: ${tData.epodComplianceRate || 0}%
- GPS Reliability: ${tData.gpsReliability || 0}%
- Total Shipments: ${tData.totalShipments || 0}
- Completed Deliveries: ${tData.deliveredCount || 0}
- Delayed Shipments: ${tData.delayedCount || 0}
- Cancellation Rate: ${tData.cancelledShipments || 0} cancelled out of ${tData.totalShipments || 0}
- Average Rating: ${tData.avgRating || 0}/5.0
- Fraud Flags: ${tData.fraudFlags.length > 0 ? tData.fraudFlags.join(', ') : 'None detected'}

Generate a report with these sections (use plain text, no markdown):
1. OVERALL ASSESSMENT (2-3 sentences summarizing reliability)
2. STRENGTHS (bullet points of what they do well)
3. RISK FACTORS (any concerns based on the data)
4. RECOMMENDATION (whether recommended for high-value, medium-risk, or low-risk shipments)
5. SUGGESTED ACTIONS (specific improvement suggestions)

Be specific and data-driven. Reference the actual numbers.
`;
            break;

        case 'fraud_analysis':
            firestoreField = 'aiFraudAnalysis';
            const flagsText = tData.fraudFlags.length > 0
                ? tData.fraudFlags.join('\n- ')
                : 'No fraud flags detected';
            prompt = `
You are an AI fraud detection analyst for TrustNet AI logistics platform.
Analyze potential fraud indicators for this transporter.

TRANSPORTER FRAUD DATA:
- Trust Score: ${tData.trustScore || 0}/100
- Total Shipments: ${tData.totalShipments || 0}
- Fraud Flags Detected:
- ${flagsText}
- GPS Reliability: ${tData.gpsReliability || 0}%
- ePOD Compliance: ${tData.epodComplianceRate || 0}%
- Cancellations: ${tData.cancelledShipments || 0}

Analyze and provide (use plain text, no markdown):
1. FRAUD RISK LEVEL: LOW / MEDIUM / HIGH (with justification)
2. SUSPICIOUS PATTERNS (what anomalies were found)
3. RISK ASSESSMENT (detailed analysis of each flag)
4. RECOMMENDED ACTIONS (what the business should do)
5. MONITORING SUGGESTIONS (what to watch for)

Be thorough and reference the actual data.
`;
            break;

        case 'delivery_prediction':
            firestoreField = 'aiDeliveryPrediction';
            const delayRate = tData.totalShipments > 0
                ? ((tData.delayedCount / tData.totalShipments) * 100).toFixed(1)
                : 0;
            prompt = `
You are an AI predictive analyst for TrustNet AI logistics platform.
Based on historical performance, predict future delivery behavior.

TRANSPORTER PERFORMANCE DATA:
- Trust Score: ${tData.trustScore || 0}/100
- On-time Rate: ${tData.onTimeRate || 0}%
- Total Shipments: ${tData.totalShipments || 0}
- Delayed Shipments: ${tData.delayedCount || 0} (${delayRate}%)
- GPS Reliability: ${tData.gpsReliability || 0}%
- ePOD Compliance: ${tData.epodComplianceRate || 0}%
- Average Rating: ${tData.avgRating || 0}/5.0
- Cancellations: ${tData.cancelledShipments || 0}

Predict and provide (use plain text, no markdown):
1. DELAY PROBABILITY: percentage chance next shipment will be delayed
2. FAILURE RISK: LOW / MEDIUM / HIGH with reasoning
3. EXPECTED BEHAVIOR: how this transporter will likely perform
4. OPTIMAL USE CASES: what types of shipments suit this transporter
5. IMPROVEMENT FORECAST: expected trajectory if current trends continue

Be data-driven and specific with predictions.
`;
            break;
    }

    try {
        const aiText = await callGemini(prompt);
        const resultText = aiText || 'AI analysis could not be generated at this time. Please try again later.';

        // Save to Firestore
        const updateData = {
            [firestoreField]: resultText,
            aiUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        await db.collection('users').doc(transporterId).update(updateData);

        return { success: true, report: resultText, type };
    } catch (e) {
        console.error(`Error generating ${type}:`, e);
        throw new functions.https.HttpsError('internal', `Failed to generate ${type}: ${e.message}`);
    }
});

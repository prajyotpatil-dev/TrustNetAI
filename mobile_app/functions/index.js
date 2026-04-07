const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fetch = require('node-fetch');

admin.initializeApp();
const db = admin.firestore();

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

        // Fetch all shipments for this transporter
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

            // Completion & On-Time Logic
            if (shipment.status === 'delivered') {
                completedDeliveries++;
                if (!shipment.delayInMinutes || shipment.delayInMinutes <= 0) {
                    onTimeDeliveries++;
                }
            }

            // Cancellation Logic
            if (shipment.status === 'cancelled' || shipment.cancellationFlag === true) {
                cancelledShipments++;
            }

            // Proof Logic
            if (shipment.epodUrl || shipment.proofUploaded === true) {
                shipmentsWithProof++;
            }

            // GPS Logic
            if (shipment.gpsUpdatesCount > 0) {
                totalGpsUpdates += shipment.gpsUpdatesCount;
            }
            if (shipment.status === 'in_transit' || shipment.status === 'delivered') {
                expectedGpsUpdates += EXPECTED_UPDATES_PER_TRIP;
            }
        });

        if (totalShipments === 0) return null;

        // Fetch transporter user data for avgRating
        const userDoc = await userRef.get();
        let avgRating = 5.0;
        if (userDoc.exists && userDoc.data().avgRating !== undefined) {
            avgRating = userDoc.data().avgRating;
        }

        // Calculate ratios
        const onTimeRate = completedDeliveries > 0 ? (onTimeDeliveries / completedDeliveries) : 1;
        const proofRate = totalShipments > 0 ? (shipmentsWithProof / totalShipments) : 1;
        const gpsScore = expectedGpsUpdates > 0 ? Math.min(totalGpsUpdates / expectedGpsUpdates, 1) : (totalGpsUpdates > 0 ? 1 : 0);
        const cancelPenalty = totalShipments > 0 ? (cancelledShipments / totalShipments) : 0;

        // Weights
        const weightOnTime = onTimeRate * 40;
        const weightProof = proofRate * 20;
        const weightGps = gpsScore * 15;
        const weightCancel = (1 - cancelPenalty) * 15;
        const weightRating = (avgRating / 5.0) * 10;

        let finalScore = weightOnTime + weightProof + weightGps + weightCancel + weightRating;
        finalScore = Math.max(0, Math.min(100, finalScore)); // Clamp between 0-100

        // Create breakdown JSON
        const trustBreakdown = {
            onTimeRate: onTimeRate,
            proofRate: proofRate,
            gpsScore: gpsScore,
            cancelPenalty: cancelPenalty,
            avgRating: avgRating,
            breakdownPct: {
                onTime: weightOnTime,
                proof: weightProof,
                gps: weightGps,
                cancel: weightCancel,
                rating: weightRating
            }
        };

        console.log(`Final trust score for ${transporterId}: ${finalScore}`);

        await userRef.set({
            trustScore: finalScore,
            totalShipments: totalShipments,
            completedTrips: completedDeliveries,
            cancelledShipments: cancelledShipments,
            onTimeRate: onTimeRate * 100,
            epodComplianceRate: proofRate * 100,
            gpsReliability: gpsScore * 100,
            trustBreakdown: trustBreakdown,
            avgRating: avgRating
        }, { merge: true });

        return { success: true, trustScore: finalScore };
    });

exports.generateTrustReport = functions.firestore
    .document('users/{userId}')
    .onUpdate(async (change, context) => {
        const afterData = change.after.data();

        // Ensure it's a transporter
        if (afterData.role !== 'transporter') return null;

        // Only generate exactly when the trustScore changes to prevent loop
        if (change.before.data().trustScore === afterData.trustScore) {
            return null;
        }

        const GEMINI_API_KEY = "AIzaSyAYsBeiGlp1tXaRodw249qq8bZrzyPD8cQ";

        const prompt = `
Analyze this transporter:

Trust Score: ${afterData.trustScore}
On-time Rate: ${afterData.onTimeRate}
Proof Compliance: ${afterData.epodComplianceRate}
GPS Reliability: ${afterData.gpsReliability}
Cancellation Rate: ${afterData.cancellationRate}
Rating: ${afterData.avgRating}

Generate:
- Summary
- Strengths
- Risks
- Recommendation
`;

        const response = await fetch(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=" + GEMINI_API_KEY,
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    contents: [
                        {
                            parts: [{ text: prompt }],
                        },
                    ],
                }),
            }
        );

        const data = await response.json();

        const aiText =
            data?.candidates?.[0]?.content?.parts?.[0]?.text || "No report generated";

        await admin.firestore()
            .collection("users")
            .doc(context.params.userId)
            .update({
                aiReport: aiText,
            });

        return null;
    });

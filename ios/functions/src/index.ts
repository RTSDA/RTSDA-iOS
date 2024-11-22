import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as sgMail from '@sendgrid/mail';

admin.initializeApp();
sgMail.setApiKey(functions.config().sendgrid.key);

export const onNewPrayerRequest = functions.firestore
    .document('prayerRequests/{requestId}')
    .onCreate(async (snap, context) => {
        const request = snap.data();
        
        // Get all admin emails from the subscriptions collection
        const subscribersSnapshot = await admin.firestore()
            .collection('notificationSubscriptions')
            .get();
            
        const emails = subscribersSnapshot.docs.map(doc => doc.data().email);
        
        if (emails.length === 0) return;
        
        const msg = {
            to: emails,
            from: 'noreply@rockvilletollandsda.org',
            subject: 'New Prayer Request Submitted',
            text: `
                A new prayer request has been submitted:
                
                From: ${request.name}
                Type: ${request.requestType}
                Confidential: ${request.isConfidential ? 'Yes' : 'No'}
                
                Details:
                ${request.details}
                
                You can view this request in the admin panel.
            `,
            html: `
                <h2>New Prayer Request</h2>
                <p>A new prayer request has been submitted:</p>
                <p><strong>From:</strong> ${request.name}</p>
                <p><strong>Type:</strong> ${request.requestType}</p>
                <p><strong>Confidential:</strong> ${request.isConfidential ? 'Yes' : 'No'}</p>
                <p><strong>Details:</strong><br>${request.details}</p>
                <p>You can view this request in the admin panel.</p>
            `
        };
        
        try {
            await sgMail.send(msg);
            console.log('Notification email sent successfully');
        } catch (error) {
            console.error('Error sending notification email:', error);
        }
    });

export const managePrayerRequestSubscription = functions.https.onCall(async (data, context) => {
    // Verify the user is an admin
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const adminDoc = await admin.firestore()
        .collection('admins')
        .doc(context.auth.uid)
        .get();
        
    if (!adminDoc.exists) {
        throw new functions.https.HttpsError('permission-denied', 'User must be an admin');
    }
    
    const { email, action } = data;
    
    if (action === 'subscribe') {
        await admin.firestore()
            .collection('notificationSubscriptions')
            .doc(email)
            .set({
                email: email,
                userId: context.auth.uid,
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            });
            
        return { success: true, message: 'Successfully subscribed to notifications' };
    } else if (action === 'unsubscribe') {
        await admin.firestore()
            .collection('notificationSubscriptions')
            .doc(email)
            .delete();
            
        return { success: true, message: 'Successfully unsubscribed from notifications' };
    }
    
    throw new functions.https.HttpsError('invalid-argument', 'Invalid action specified');
}); 
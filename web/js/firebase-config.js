// Import Firebase modules
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js";
import { getFirestore, collection, query, orderBy, onSnapshot, doc, updateDoc, deleteDoc, addDoc, serverTimestamp } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js";

// Your web app's Firebase configuration
const firebaseConfig = {
    apiKey: "AIzaSyACF3SZf_GBWziLeEbCIAaimiuEt28UQN4",
    authDomain: "rtsda-b42ce.firebaseapp.com",
    projectId: "rtsda-b42ce",
    storageBucket: "rtsda-b42ce.appspot.com",
    messagingSenderId: "447561031868",
    appId: "1:447561031868:web:3b131806a88cb3d82530b9",
    measurementId: "G-CD7LH69H7Y"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Get Firestore instance
const db = getFirestore(app);

// Get Auth instance
const auth = getAuth(app);

// Create a service class to match Android implementation
class PrayerRequestService {
    constructor() {
        this.collection = collection(db, "prayerRequests"); // Using the same collection as admin panel
    }

    async submitRequest(request) {
        try {
            // Use serverTimestamp for consistency with web form
            const docRef = await addDoc(this.collection, {
                ...request,
                status: 'new',
                timestamp: serverTimestamp(), // Use serverTimestamp instead of new Date()
            });
            await updateDoc(doc(db, 'prayerRequests', docRef.id), { 
                id: docRef.id 
            });
            return true;
        } catch (e) {
            console.error("Error submitting prayer request:", e);
            return false;
        }
    }

    // Get all prayer requests (for admin)
    subscribeToRequests(callback) {
        const q = query(this.collection, orderBy("timestamp", "desc"));
        return onSnapshot(q, (snapshot) => {
            const requests = [];
            snapshot.forEach((doc) => {
                requests.push({ id: doc.id, ...doc.data() });
            });
            callback(requests);
        }, (error) => {
            console.error("Error getting prayer requests:", error);
            callback(null, error);
        });
    }

    // Update prayer request status (for admin)
    async updateStatus(requestId, status) {
        try {
            await updateDoc(doc(db, 'prayerRequests', requestId), {
                status: status
            });
            return true;
        } catch (e) {
            console.error("Error updating prayer request status:", e);
            return false;
        }
    }

    // Delete prayer request (for admin)
    async deleteRequest(requestId) {
        try {
            await deleteDoc(doc(db, 'prayerRequests', requestId));
            return true;
        } catch (e) {
            console.error("Error deleting prayer request:", e);
            return false;
        }
    }
}

// Export what we need
export { db, auth, PrayerRequestService };
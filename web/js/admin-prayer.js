import { getFirestore, collection, query, orderBy, onSnapshot, doc, updateDoc, deleteDoc, serverTimestamp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js';
import { db } from './firebase-config.js';

export function initializePrayerRequestsAdmin() {
    const prayerRequestsContainer = document.getElementById('prayerRequestsList');
    
    if (!prayerRequestsContainer) {
        console.error('Prayer requests container not found');
        return;
    }

    // Listen for prayer requests in real-time
    const q = query(collection(db, 'prayerRequests'), orderBy('timestamp', 'desc'));
    
    onSnapshot(q, (snapshot) => {
        let html = '';
        snapshot.forEach((doc) => {
            const request = doc.data();
            
            // Skip if timestamp is not yet set (still pending)
            if (!request.timestamp) return;

            const date = request.timestamp.toDate().toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'long',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
            
            const privacyBadge = request.isPrivate ? 
                '<span class="badge badge--private">Private</span>' : 
                '<span class="badge badge--public">Public</span>';
            
            html += `
                <div class="prayer-request-card ${request.isPrivate ? 'prayer-request-card--private' : ''}" data-id="${doc.id}">
                    <div class="prayer-request-header">
                        <div class="prayer-request-title">
                            <h3>${request.name}</h3>
                            ${privacyBadge}
                        </div>
                        <span class="prayer-date">${date}</span>
                    </div>
                    <div class="prayer-request-content">
                        <p>${request.request}</p>
                        <div class="contact-info">
                            <p><strong>Email:</strong> ${request.email || 'Not provided'}</p>
                            <p><strong>Phone:</strong> ${request.phone ? `<a href="tel:${request.phone}">${request.phone}</a>` : 'Not provided'}</p>
                        </div>
                    </div>
                    <div class="prayer-request-actions">
                        <select class="status-select" onchange="updatePrayerStatus('${doc.id}', this.value)">
                            <option value="new" ${request.status === 'new' ? 'selected' : ''}>New</option>
                            <option value="prayed" ${request.status === 'prayed' ? 'selected' : ''}>Prayed For</option>
                            <option value="completed" ${request.status === 'completed' ? 'selected' : ''}>Completed</option>
                        </select>
                        <button onclick="deletePrayerRequest('${doc.id}')" class="btn btn--stroke btn--small">Delete</button>
                    </div>
                </div>
            `;
        });
        
        prayerRequestsContainer.innerHTML = html || '<p>No prayer requests found.</p>';
    }, (error) => {
        console.error('Error getting prayer requests:', error);
        prayerRequestsContainer.innerHTML = '<p>Error loading prayer requests. Please try again later.</p>';
    });
}

// Update prayer request status
window.updatePrayerStatus = async function(id, status) {
    try {
        await updateDoc(doc(db, 'prayerRequests', id), {
            status: status,
            timestamp: serverTimestamp()
        });
    } catch (error) {
        console.error('Error updating prayer request status:', error);
        alert('Failed to update status. Please try again.');
    }
};

// Delete prayer request
window.deletePrayerRequest = async function(id) {
    if (confirm('Are you sure you want to delete this prayer request?')) {
        try {
            await deleteDoc(doc(db, 'prayerRequests', id));
        } catch (error) {
            console.error('Error deleting prayer request:', error);
            alert('Failed to delete prayer request. Please try again.');
        }
    }
};

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', initializePrayerRequestsAdmin);

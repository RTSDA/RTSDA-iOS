import { db } from './firebase-config.js';
import { collection, addDoc, getDocs, deleteDoc, doc, updateDoc, Timestamp, query, orderBy, getDoc } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";
import { getAuth, signInWithEmailAndPassword, signOut, onAuthStateChanged } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js";
import { initializePrayerRequestsAdmin } from './admin-prayer.js';

// Global variables
let currentlyEditing = null;
let eventsList = null;
let addEventForm = null;

// Helper function to format recurrence type
function formatRecurrenceType(type) {
    if (!type || type === 'NONE') return '';
    return type.split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
        .join(' ');
}

// Calculate next occurrence of a recurring event
function calculateNextDate(currentDate, recurrenceType) {
    const nextDate = new Date(currentDate);
    
    switch (recurrenceType.toUpperCase()) {
        case 'WEEKLY':
            nextDate.setDate(nextDate.getDate() + 7);
            break;
            
        case 'BIWEEKLY':
            nextDate.setDate(nextDate.getDate() + 14);
            break;
            
        case 'MONTHLY':
            nextDate.setMonth(nextDate.getMonth() + 1);
            break;
            
        case 'FIRST_TUESDAY':
            // Move to first day of next month
            nextDate.setMonth(nextDate.getMonth() + 1);
            nextDate.setDate(1);
            
            // Find first Tuesday
            while (nextDate.getDay() !== 2) { // 2 = Tuesday
                nextDate.setDate(nextDate.getDate() + 1);
            }
            break;
            
        default:
            return null;
    }
    
    return nextDate;
}

// Validate event dates and combine with time
function validateEventDates(dateStr, timeStr, endDateStr, endTimeStr) {
    if (!dateStr || !timeStr) return null;
    
    const startDate = new Date(dateStr + 'T' + timeStr);
    let endDate = null;
    
    if (endDateStr && endTimeStr) {
        endDate = new Date(endDateStr + 'T' + endTimeStr);
        
        if (endDate <= startDate) {
            alert('End date must be after start date');
            return null;
        }
    }
    
    return {
        startDate,
        endDate
    };
}

// Load and display existing events
async function loadEvents() {
    if (!eventsList) return;
    
    try {
        const eventsQuery = query(collection(db, 'events'), orderBy('startDate', 'desc'));
        const querySnapshot = await getDocs(eventsQuery);
        let html = '';
        
        querySnapshot.forEach((doc) => {
            const event = doc.data();
            const startDate = event.startDate.toDate();
            const endDate = event.endDate ? event.endDate.toDate() : null;
            
            const formattedStartDate = startDate.toLocaleDateString('en-US', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
            
            const formattedEndDate = endDate ? endDate.toLocaleDateString('en-US', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            }) : '';
            
            const recurrenceType = formatRecurrenceType(event.recurrenceType);
            
            html += `
                <div class="event-card">
                    <h3>${event.title}</h3>
                    <p><strong>Start:</strong> ${formattedStartDate}</p>
                    ${endDate ? `<p><strong>End:</strong> ${formattedEndDate}</p>` : ''}
                    ${recurrenceType ? `<p><strong>Recurrence:</strong> ${recurrenceType}</p>` : ''}
                    <p>${event.description}</p>
                    <div class="event-actions">
                        <button onclick="editEvent('${doc.id}')" class="btn btn--stroke btn--small">Edit</button>
                        <button onclick="deleteEvent('${doc.id}')" class="btn btn--stroke btn--small">Delete</button>
                    </div>
                </div>
            `;
        });
        
        eventsList.innerHTML = html || '<p>No events found</p>';
        
    } catch (error) {
        console.error("Error loading events: ", error);
        eventsList.innerHTML = '<p>Error loading events. Please try again later.</p>';
    }
}

// Initialize event listeners and load events
function initializeEventListeners() {
    eventsList = document.getElementById('eventsList');
    addEventForm = document.getElementById('addEventForm');
    
    if (!eventsList || !addEventForm) {
        console.error('Required elements not found');
        return;
    }
    
    // Load initial events
    loadEvents();
}

// Handle form submission (add/edit events)
function setupEventForm() {
    if (!addEventForm) return;
    
    addEventForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const formData = new FormData(addEventForm);
        const dates = validateEventDates(
            formData.get('date'),
            formData.get('time'),
            formData.get('endDate'),
            formData.get('endTime')
        );
        
        if (!dates) return;
        
        const eventData = {
            title: formData.get('title'),
            description: formData.get('description'),
            startDate: Timestamp.fromDate(dates.startDate),
            endDate: dates.endDate ? Timestamp.fromDate(dates.endDate) : null,
            recurrenceType: formData.get('recurrence') || 'NONE'
        };
        
        try {
            if (currentlyEditing) {
                // Update existing event
                await updateDoc(doc(db, 'events', currentlyEditing), eventData);
                currentlyEditing = null;
            } else {
                // Add new event
                await addDoc(collection(db, 'events'), eventData);
            }
            
            // Reset form and reload events
            addEventForm.reset();
            loadEvents();
            
        } catch (error) {
            console.error("Error saving event: ", error);
            alert('Error saving event. Please try again.');
        }
    });
}

document.addEventListener('DOMContentLoaded', function() {
    const auth = getAuth();
    const loginForm = document.getElementById('loginForm');
    const loginSection = document.getElementById('loginSection');
    const adminSection = document.getElementById('adminSection');
    const logoutBtn = document.getElementById('logoutBtn');
    const offlineWarning = document.getElementById('offlineWarning');

    if (!loginForm || !loginSection || !adminSection || !logoutBtn) {
        console.error('Required elements not found');
        return;
    }

    // Handle offline/online status
    function updateOnlineStatus() {
        if (offlineWarning) {
            offlineWarning.style.display = navigator.onLine ? 'none' : 'block';
        }
    }

    window.addEventListener('online', updateOnlineStatus);
    window.addEventListener('offline', updateOnlineStatus);
    updateOnlineStatus(); // Initial check

    // Handle authentication state changes
    onAuthStateChanged(auth, (user) => {
        if (user) {
            // User is signed in
            console.log('User signed in:', user.email);
            loginSection.style.display = 'none';
            adminSection.style.display = 'block';
            setupEventForm();
            initializeEventListeners();
            initializePrayerRequestsAdmin();
            // Show prayers tab by default
            window.showTab('prayers');
        } else {
            // User is signed out
            console.log('User signed out');
            loginSection.style.display = 'block';
            adminSection.style.display = 'none';
        }
    });

    // Handle login
    loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const email = loginForm.email.value;
        const password = loginForm.password.value;

        try {
            await signInWithEmailAndPassword(auth, email, password);
            loginForm.reset();
        } catch (error) {
            console.error("Error signing in: ", error);
            alert('Login failed. Please check your credentials.');
        }
    });

    // Handle logout
    logoutBtn.addEventListener('click', async () => {
        try {
            await signOut(auth);
        } catch (error) {
            console.error("Error signing out: ", error);
        }
    });

    // Add tab functionality to window scope
    window.showTab = function(tabName) {
        console.log('Showing tab:', tabName);
        
        // Get all tab buttons and content
        const tabButtons = document.querySelectorAll('.admin-tab');
        const tabContents = document.querySelectorAll('.admin-content');
        
        // Remove active class from all buttons
        tabButtons.forEach(button => {
            if (button.getAttribute('data-tab') === tabName) {
                button.classList.add('active');
            } else {
                button.classList.remove('active');
            }
        });
        
        // Hide all content sections
        tabContents.forEach(content => {
            if (content.id === tabName + 'Tab') {
                content.style.display = 'block';
                
                // If showing prayers tab, initialize it
                if (tabName === 'prayers') {
                    initializePrayerRequestsAdmin();
                }
                // If showing events tab, reload events
                if (tabName === 'events') {
                    loadEvents();
                }
            } else {
                content.style.display = 'none';
            }
        });
    };
});

// Add edit function to window scope
window.editEvent = async function(eventId) {
    if (!addEventForm) return;
    
    try {
        const eventDoc = await getDoc(doc(db, 'events', eventId));
        if (!eventDoc.exists()) {
            console.error('Event not found');
            return;
        }
        
        const event = eventDoc.data();
        currentlyEditing = eventId;
        
        // Fill form with event data
        addEventForm.title.value = event.title;
        addEventForm.description.value = event.description;
        
        const startDate = event.startDate.toDate();
        addEventForm.date.value = startDate.toISOString().split('T')[0];
        addEventForm.time.value = startDate.toTimeString().slice(0, 5);
        
        if (event.endDate) {
            const endDate = event.endDate.toDate();
            addEventForm.endDate.value = endDate.toISOString().split('T')[0];
            addEventForm.endTime.value = endDate.toTimeString().slice(0, 5);
        }
        
        addEventForm.recurrence.value = event.recurrenceType || 'NONE';
        
        // Show events tab and scroll to form
        window.showTab('events');
        addEventForm.scrollIntoView({ behavior: 'smooth' });
        
    } catch (error) {
        console.error("Error loading event for editing: ", error);
        alert('Error loading event. Please try again.');
    }
};

// Add delete function to window scope
window.deleteEvent = async function(eventId) {
    if (confirm('Are you sure you want to delete this event?')) {
        try {
            await deleteDoc(doc(db, 'events', eventId));
            loadEvents();
        } catch (error) {
            console.error("Error deleting event: ", error);
            alert('Error deleting event. Please try again.');
        }
    }
};
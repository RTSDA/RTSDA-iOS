import { initializeFirebase, db, auth } from './firebase-config.js';
import { 
    collection, 
    query, 
    orderBy, 
    getDocs, 
    where, 
    Timestamp, 
    setDoc, 
    doc,
    updateDoc,
    addDoc,
    deleteDoc,
    getDoc
} from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";

// Helper function to format recurrence type
function formatRecurrenceType(type) {
    if (!type || type === 'NONE') return '';
    return type.split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
        .join(' ');
}

// Format date and time
function formatDateTime(date, time) {
    const eventDate = date instanceof Date ? date : date.toDate();
    const formattedDate = eventDate.toLocaleDateString('en-US', {
        weekday: 'long',
        month: 'long',
        day: 'numeric',
        year: 'numeric'
    });
    return time ? `${formattedDate} at ${time}` : formattedDate;
}

// Helper function to get the correct HTML file for an event
function getEventPage(title) {
    if (!title) return 'events.html';
    
    const titleLower = title.toLowerCase().trim();
    
    // Check for specific prayer events first
    if (titleLower.includes('prayer')) {
        // Check for specific prayer meetings first
        if (titleLower.includes('bi-weekly') || 
            titleLower.includes('biweekly') || 
            titleLower.includes('bi weekly')) {
            return 'Biweeklyprayer.html';
        }
        if (titleLower.includes('monthly')) {
            return 'Monthlyprayermeeting.html';
        }
        if (titleLower.includes('new year') || titleLower.includes('end of year')) {
            return 'newyearprayer.html';
        }
        return 'Prayer.html';
    }
    
    if (titleLower.includes('bible study')) {
        return 'Biblestudyregister.html';
    }
    if (titleLower.includes('emmanuel')) {
        return 'Emmanuel.html';
    }
    
    return 'events.html';
}

// Helper function to convert any date format to Date object
function getDate(event) {
    if (!event.startDate) return new Date(0);
    
    if (event.startDate instanceof Date) return event.startDate;
    if (event.startDate instanceof Timestamp) return event.startDate.toDate();
    if (typeof event.startDate === 'number') return new Date(event.startDate * 1000);
    if (event.startDate?.seconds) return new Date(event.startDate.seconds * 1000);
    return new Date(event.startDate);
}

// Load and display existing events
async function loadEvents() {
    console.log('Starting events load...');
    try {
        // Initialize Firebase first
        await initializeFirebase();
        
        if (!db) {
            throw new Error('Firebase database not initialized');
        }
        
        console.log('Firebase initialized successfully, fetching events...');
        
        const eventsList = document.getElementById('events-container');
        if (!eventsList) {
            throw new Error('Events container not found');
        }

        const eventsRef = collection(db, 'events');
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        const q = query(
            eventsRef,
            where('startDate', '>=', Timestamp.fromDate(today)),
            orderBy('startDate', 'asc')
        );
        
        console.log('Executing query...');
        const querySnapshot = await getDocs(q);
        console.log('Query complete, processing results...');
        
        if (querySnapshot.empty) {
            eventsList.innerHTML = `
                <div class="column event-block">
                    <div class="event-block__content">
                        <h3>No Upcoming Events</h3>
                        <p>Check back soon for new events!</p>
                    </div>
                </div>`;
            return;
        }
        
        // Process and sort events
        const events = querySnapshot.docs
            .map(doc => {
                const data = doc.data();
                return { id: doc.id, ...data };
            })
            .map(event => ({
                ...event,
                startDate: getDate(event),
                endDate: event.endDate ? getDate({ startDate: event.endDate }) : null
            }))
            .sort((a, b) => a.startDate - b.startDate);
        
        console.log('Processed events:', events);
        
        // Generate HTML for events
        const eventsHTML = events.map(event => {
            const eventUrl = getEventPage(event.title);
            const recurrenceLabel = formatRecurrenceType(event.recurrenceType);
            
            return `
                <div class="column event-block">
                    <div class="event-block__content">
                        <h3>
                            <a href="${eventUrl}" class="event-block__title">
                                ${event.title || 'Untitled Event'}
                            </a>
                        </h3>
                        <p class="event-block__date">
                            ${formatDateTime(event.startDate, event.time)}
                        </p>
                        ${event.location ? `<p class="event-block__location">Location: ${event.location}</p>` : ''}
                        ${event.description ? `<p class="event-block__desc">${event.description}</p>` : ''}
                        ${recurrenceLabel ? `<p class="event-block__recurrence">Recurs: ${recurrenceLabel}</p>` : ''}
                        ${auth.currentUser ? `
                            <div class="event-block__actions">
                                <button onclick="editEvent('${event.id}')" class="btn btn--stroke">Edit</button>
                                <button onclick="deleteEvent('${event.id}')" class="btn btn--stroke">Delete</button>
                            </div>
                        ` : ''}
                    </div>
                </div>
            `;
        }).join('');
        
        eventsList.innerHTML = eventsHTML;
        
    } catch (error) {
        console.error('Error fetching events:', error);
        const eventsList = document.getElementById('events-container');
        if (eventsList) {
            eventsList.innerHTML = `
                <div class="column event-block">
                    <div class="event-block__content">
                        <h3>Error Loading Events</h3>
                        <p>Please try again later.</p>
                    </div>
                </div>`;
        }
    }
}

// Delete an event
async function deleteEvent(eventId) {
    if (!confirm('Are you sure you want to delete this event?')) {
        return;
    }
    
    try {
        await deleteDoc(doc(db, 'events', eventId));
        alert('Event deleted successfully!');
        await loadEvents();
    } catch (error) {
        console.error('Error deleting event:', error);
        alert('Error deleting event. Please try again later.');
    }
}

// Edit an event
async function editEvent(eventId) {
    try {
        const eventDoc = await getDoc(doc(db, 'events', eventId));
        if (!eventDoc.exists()) {
            alert('Event not found');
            return;
        }
        
        const event = eventDoc.data();
        
        // Populate form fields
        const form = document.getElementById('addEventForm');
        if (!form) {
            alert('Event edit form not found');
            return;
        }
        
        form.title.value = event.title || '';
        form.description.value = event.description || '';
        form.location.value = event.location || '';
        form.time.value = event.time || '';
        form.recurrenceType.value = event.recurrenceType || 'NONE';
        
        // Convert Timestamp to date string
        if (event.startDate) {
            const startDate = event.startDate instanceof Timestamp 
                ? event.startDate.toDate() 
                : new Date(event.startDate.seconds * 1000);
            form.startDate.value = startDate.toISOString().split('T')[0];
        }
        
        if (event.endDate) {
            const endDate = event.endDate instanceof Timestamp 
                ? event.endDate.toDate() 
                : new Date(event.endDate.seconds * 1000);
            form.endDate.value = endDate.toISOString().split('T')[0];
        }
        
        // Update form for editing mode
        form.dataset.editing = eventId;
        form.querySelector('button[type="submit"]').textContent = 'Update Event';
        
        // Scroll to form
        form.scrollIntoView({ behavior: 'smooth' });
    } catch (error) {
        console.error('Error loading event for editing:', error);
        alert('Error loading event for editing. Please try again later.');
    }
}

// Make functions available globally
window.deleteEvent = deleteEvent;
window.editEvent = editEvent;

// Initialize the page
document.addEventListener('DOMContentLoaded', async () => {
    try {
        await loadEvents();
    } catch (error) {
        console.error('Error initializing events page:', error);
    }
});
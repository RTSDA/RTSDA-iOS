import { db } from './firebase-config.js';
import { collection, query, orderBy, getDocs, where, Timestamp } from "https://www.gstatic.com/firebasejs/11.0.2/firebase-firestore.js";

// Helper function to format recurrence type
function formatRecurrenceType(type) {
    if (!type || type === 'NONE') return '';
    return type.split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
        .join(' ');
}

// Format date and time
function formatDateTime(date, time) {
    const eventDate = new Date(date);
    const formattedDate = eventDate.toLocaleDateString('en-US', {
        weekday: 'long',
        month: 'long',
        day: 'numeric',
        year: 'numeric'
    });
    return `${formattedDate} at ${time}`;
}

// Helper function to get the correct HTML file for an event
function getEventPage(title) {
    const titleLower = title.toLowerCase().trim();
    console.log('=== Event Routing Debug ===');
    console.log('Original title:', title);
    console.log('Lowercase title:', titleLower);
    
    // Check for specific prayer events first
    if (titleLower.includes('prayer')) {
        console.log('Contains "prayer"');
        
        // Check for specific prayer meetings first
        // Handle all variations of bi-weekly
        if (titleLower.includes('bi-weekly') || 
            titleLower.includes('biweekly') || 
            titleLower.includes('bi weekly')) {
            console.log('→ Matched bi-weekly, routing to Biweeklyprayer.html');
            return 'Biweeklyprayer.html';
        }
        if (titleLower.includes('monthly')) {
            console.log('→ Matched monthly prayer, routing to Monthlyprayermeeting.html');
            return 'Monthlyprayermeeting.html';
        }
        
        // If no specific prayer meeting matched, use general prayer page
        console.log('→ No specific prayer type matched, routing to Prayer.html');
        return 'Prayer.html';
    }
    
    // Then check for other specific pages
    if (titleLower.includes('bible study')) {
        console.log('→ Matched bible study, routing to Biblestudyregister.html');
        return 'Biblestudyregister.html';
    }
    if (titleLower.includes('emmanuel')) {
        console.log('→ Matched emmanuel, routing to Emmanuel.html');
        return 'Emmanuel.html';
    }
    
    // Default to events.html if no specific page exists
    console.log('→ No match, routing to events.html');
    return 'events.html';
}

document.addEventListener('DOMContentLoaded', async function() {
    const eventsContainer = document.getElementById('events-container');
    
    if (!eventsContainer) {
        console.error('Events container not found');
        return;
    }
    
    try {
        // Fetch upcoming events
        const eventsRef = collection(db, 'events');
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        const q = query(
            eventsRef,
            orderBy('startDate', 'asc')
        );
        
        const querySnapshot = await getDocs(q);
        
        // Filter and sort events
        const events = querySnapshot.docs
            .map(doc => ({ id: doc.id, ...doc.data() }))
            .filter(event => {
                const startDate = typeof event.startDate === 'number'
                    ? new Date(event.startDate * 1000)
                    : event.startDate instanceof Timestamp
                        ? event.startDate.toDate()
                        : event.startDate?.seconds
                            ? new Date(event.startDate.seconds * 1000)
                            : new Date(event.startDate);
                
                return startDate >= today;
            })
            .sort((a, b) => {
                const aDate = typeof a.startDate === 'number'
                    ? new Date(a.startDate * 1000)
                    : a.startDate instanceof Timestamp
                        ? a.startDate.toDate()
                        : a.startDate?.seconds
                            ? new Date(a.startDate.seconds * 1000)
                            : new Date(a.startDate);
                const bDate = typeof b.startDate === 'number'
                    ? new Date(b.startDate * 1000)
                    : b.startDate instanceof Timestamp
                        ? b.startDate.toDate()
                        : b.startDate?.seconds
                            ? new Date(b.startDate.seconds * 1000)
                            : new Date(b.startDate);
                return aDate - bDate;
            })
            .slice(0, 4); // Only show the next 4 events on the homepage
        
        if (events.length === 0) {
            eventsContainer.innerHTML = `
                <div class="column event-block">
                    <div class="event-block__content">
                        <h3>No Upcoming Events</h3>
                        <p>Check back soon for new events!</p>
                    </div>
                </div>`;
            return;
        }
        
        // Render events
        const eventsHTML = events.map(event => {
            const startDate = typeof event.startDate === 'number'
                ? new Date(event.startDate * 1000)
                : event.startDate instanceof Timestamp
                    ? event.startDate.toDate()
                    : event.startDate?.seconds
                        ? new Date(event.startDate.seconds * 1000)
                        : new Date(event.startDate);
            
            const eventPage = getEventPage(event.title);
            
            return `
                <div class="column events-list__item">
                    <h3 class="display-1 events-list__item-title">
                        <a href="${eventPage}" class="events-list__item-link">
                            ${event.title}
                        </a>
                    </h3>
                    <p class="events-list__item-desc">${event.description}</p>
                    <ul class="events-list__meta">
                        <li class="events-list__meta-date">${startDate.toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</li>
                        <li class="events-list__meta-time">${startDate.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })}${event.endTime ? ` - ${event.endTime}` : ''}</li>
                        <li class="events-list__meta-location">${event.location}${
                            event.locationUrl ? `<br><a href="${event.locationUrl}" target="_blank">View on Map</a>` : ''
                        }</li>
                    </ul>
                </div>`;
        }).join('');
        
        eventsContainer.innerHTML = eventsHTML;
        
    } catch (error) {
        console.error('Error loading events:', error);
        eventsContainer.innerHTML = `
            <div class="column event-block">
                <div class="event-block__content">
                    <h3>Error Loading Events</h3>
                    <p>Please try again later.</p>
                </div>
            </div>`;
    }
});

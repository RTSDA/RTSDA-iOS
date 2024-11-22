import { db } from './firebase-config.js';
import { collection, query, orderBy, getDocs, where, Timestamp, setDoc, doc } from "https://www.gstatic.com/firebasejs/11.0.2/firebase-firestore.js";

// Helper function to format recurrence type
function formatRecurrenceType(type) {
    if (!type || type === 'NONE') return '';
    return type.split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
        .join(' ');
}

// Calculate next occurrence of a recurring event
function calculateNextDate(date, recurrenceType) {
    const nextDate = new Date(date);
    
    switch (recurrenceType) {
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

// Sync recurring events
async function syncRecurringEvents() {
    try {
        console.log('Starting recurring events sync...');
        const eventsRef = collection(db, 'events');
        const now = new Date();
        
        // Get all recurring events
        const recurringQuery = query(
            eventsRef,
            where('recurrenceType', '!=', 'NONE')
        );
        
        const recurringSnapshot = await getDocs(recurringQuery);
        console.log('Found recurring events:', recurringSnapshot.size);
        
        // Process each recurring event to ensure its next date is correct
        for (const docSnap of recurringSnapshot.docs) {
            const event = { id: docSnap.id, ...docSnap.data() };
            console.log('Processing recurring event:', event.title);
            
            // Convert Firestore timestamp to Date
            let currentDate;
            if (event.startDate instanceof Timestamp) {
                currentDate = event.startDate.toDate();
            } else if (typeof event.startDate === 'number') {
                currentDate = new Date(event.startDate * 1000);
            } else if (event.startDate?.seconds) {
                currentDate = new Date(event.startDate.seconds * 1000);
            } else {
                console.error('Invalid startDate for event:', event);
                continue;
            }
            
            // If the event start is in the past, update it to the next occurrence
            if (currentDate < now) {
                while (currentDate < now) {
                    const nextDate = calculateNextDate(currentDate, event.recurrenceType);
                    if (!nextDate) break;
                    currentDate = nextDate;
                }
                
                // Calculate new end date based on duration
                let duration = 3600; // Default 1 hour
                if (event.endDate) {
                    const endDate = event.endDate instanceof Timestamp
                        ? event.endDate.toDate()
                        : typeof event.endDate === 'number'
                            ? new Date(event.endDate * 1000)
                            : event.endDate?.seconds
                                ? new Date(event.endDate.seconds * 1000)
                                : null;
                    
                    if (endDate) {
                        const startDate = event.startDate instanceof Timestamp
                            ? event.startDate.toDate()
                            : typeof event.startDate === 'number'
                                ? new Date(event.startDate * 1000)
                                : event.startDate?.seconds
                                    ? new Date(event.startDate.seconds * 1000)
                                    : null;
                        
                        duration = (endDate.getTime() - startDate.getTime()) / 1000;
                    }
                }
                
                const newStartSeconds = Math.floor(currentDate.getTime() / 1000);
                const newEndSeconds = newStartSeconds + duration;
                
                // Update the event with new dates
                await setDoc(doc(eventsRef, event.id), {
                    ...event,
                    startDate: newStartSeconds,
                    endDate: newEndSeconds
                });
                
                console.log('Updated recurring event:', event.title, 'to', currentDate);
            }
        }
        
        console.log('Recurring events sync completed');
    } catch (error) {
        console.error('Error syncing recurring events:', error);
    }
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
    console.log('Starting to load events...');
    const eventsContainer = document.getElementById('events-container');
    
    try {
        // First sync recurring events
        await syncRecurringEvents();
        
        // Then fetch upcoming events
        const eventsRef = collection(db, 'events');
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        // Query for all events, including recurring ones
        const q = query(
            eventsRef,
            orderBy('startDate', 'asc')
        );
        
        console.log('Fetching events from Firebase...');
        const querySnapshot = await getDocs(q);
        console.log('Found events:', querySnapshot.size);
        
        eventsContainer.innerHTML = ''; // Clear existing events
        
        if (querySnapshot.empty) {
            console.log('No events found in collection');
            eventsContainer.innerHTML = '<p>No upcoming events.</p>';
            return;
        }
        
        // Filter and sort events
        const events = querySnapshot.docs
            .map(doc => {
                const data = { id: doc.id, ...doc.data() };
                console.log('Event data:', data);
                return data;
            })
            .filter(event => {
                // Convert startDate to Date object for comparison
                const startDate = typeof event.startDate === 'number'
                    ? new Date(event.startDate * 1000)
                    : event.startDate instanceof Timestamp
                        ? event.startDate.toDate()
                        : event.startDate?.seconds
                            ? new Date(event.startDate.seconds * 1000)
                            : new Date(event.startDate);
                
                const isUpcoming = startDate >= today;
                console.log(`Event "${event.title}" - isUpcoming: ${isUpcoming}`);
                return isUpcoming;
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
            });
        
        console.log('Filtered events:', events);
        
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
            console.log(`Event "${event.title}" routing to: ${eventPage}`);
            
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
        
        console.log('Setting innerHTML with events:', eventsHTML);
        eventsContainer.innerHTML = eventsHTML;
    } catch (error) {
        console.error('Error fetching events:', error);
        eventsContainer.innerHTML = '<p>Error loading events. Please try again later.</p>';
    }
});
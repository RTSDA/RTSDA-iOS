import { initializeFirebase, db } from './firebase-config.js';
import { collection, query, orderBy, limit, getDocs, where, Timestamp, setDoc, doc, deleteDoc, addDoc, updateDoc } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";

let firestore;

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

// Update recurring events that have passed
async function updateRecurringEvents() {
    try {
        await initializeFirebase();
        if (!db) {
            throw new Error('Firebase database not initialized');
        }
        
        console.log('Starting recurring events update...');
        const eventsRef = collection(db, 'events');
        
        // Get all recurring events that need updating
        const now = new Date();
        const nowTimestamp = Math.floor(now.getTime() / 1000);
        
        // Get all recurring events
        const q = query(
            eventsRef,
            where('recurrenceType', '!=', 'NONE')
        );
        
        const querySnapshot = await getDocs(q);
        console.log(`Found ${querySnapshot.size} total recurring events`);
        
        let updatedCount = 0;
        
        for (const docSnapshot of querySnapshot.docs) {
            const event = {
                id: docSnapshot.id,
                ...docSnapshot.data()
            };
            
            console.log(`Processing recurring event: ${event.title} (${event.recurrenceType})`);
            
            // Convert startDate to number if it's not already
            const startTimestamp = typeof event.startDate === 'number'
                ? event.startDate
                : event.startDate instanceof Timestamp
                    ? event.startDate.seconds
                    : Math.floor(new Date(event.startDate).getTime() / 1000);
            
            console.log(`Current start timestamp: ${startTimestamp} (${new Date(startTimestamp * 1000)})`);
            console.log(`Current time: ${nowTimestamp} (${now})`);
            
            // If the event date has passed, calculate next occurrence
            if (startTimestamp < nowTimestamp) {
                let nextDate = new Date(startTimestamp * 1000);
                
                // Find the next occurrence after now
                while (nextDate < now) {
                    const calculatedNext = calculateNextDate(nextDate, event.recurrenceType);
                    if (!calculatedNext) break;
                    nextDate = calculatedNext;
                    console.log(`Calculated next date: ${nextDate}`);
                }
                
                // Calculate new end date based on duration
                const endTimestamp = typeof event.endDate === 'number'
                    ? event.endDate
                    : event.endDate instanceof Timestamp
                        ? event.endDate.seconds
                        : event.endDate
                            ? Math.floor(new Date(event.endDate).getTime() / 1000)
                            : startTimestamp + 3600; // Default 1 hour
                
                const duration = endTimestamp - startTimestamp;
                const newStartSeconds = Math.floor(nextDate.getTime() / 1000);
                const newEndSeconds = newStartSeconds + duration;
                
                console.log(`Updating event dates:
                    Start: ${new Date(newStartSeconds * 1000)}
                    End: ${new Date(newEndSeconds * 1000)}
                    Duration: ${duration} seconds`);
                
                // Update the event with new dates
                await updateDoc(doc(db, 'events', event.id), {
                    startDate: newStartSeconds,
                    endDate: newEndSeconds
                });
                
                console.log(`Updated recurring event "${event.title}" to next occurrence:`, 
                    new Date(newStartSeconds * 1000).toLocaleString());
                
                updatedCount++;
            } else {
                console.log(`Event date has not passed yet: ${new Date(startTimestamp * 1000)}`);
            }
        }
        
        console.log(`Finished updating recurring events. Updated ${updatedCount} events.`);
    } catch (error) {
        console.error('Error updating recurring events:', error);
    }
}

// Sync recurring events
async function syncRecurringEvents() {
    try {
        await initializeFirebase();
        if (!db) {
            throw new Error('Firebase database not initialized');
        }
        
        console.log('Starting recurring events sync...');
        
        const eventsRef = collection(db, 'events');
        
        // Get all recurring events
        const q = query(
            eventsRef,
            where('recurrenceType', '!=', 'NONE')
        );
        
        const querySnapshot = await getDocs(q);
        const recurringEvents = querySnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));
        
        console.log('Found recurring events:', recurringEvents.length);
        
        const now = Math.floor(Date.now() / 1000);
        
        // First, delete all past instances
        const oldInstancesQuery = query(
            eventsRef,
            where('parentEventId', '!=', null),
            where('startDate', '<', now)
        );
        
        const oldInstancesSnapshot = await getDocs(oldInstancesQuery);
        
        if (oldInstancesSnapshot.docs.length > 0) {
            console.log('Deleting old instances:', oldInstancesSnapshot.docs.length);
            await Promise.all(oldInstancesSnapshot.docs.map(doc => deleteDoc(doc.ref)));
        }
        
        // Then get current instances (after deletion of old ones)
        const currentInstancesQuery = query(
            eventsRef,
            where('parentEventId', '!=', null),
            where('startDate', '>=', now)
        );
        
        const currentInstancesSnapshot = await getDocs(currentInstancesQuery);
        
        // Update recurring events
        await updateRecurringEvents();
        
        console.log('Finished syncing recurring events');
    } catch (error) {
        console.error('Error syncing recurring events:', error);
    }
}

document.addEventListener('DOMContentLoaded', async function() {
    const eventsContainer = document.getElementById('events-container');
    const addEventForm = document.getElementById('addEventForm');
    const eventsList = document.getElementById('eventsList');
    const offlineWarning = document.getElementById('offlineWarning');
    
    if (!eventsContainer || !addEventForm || !eventsList || !offlineWarning) {
        console.error('Required DOM elements not found');
        return;
    }

    try {
        // First sync recurring events
        await syncRecurringEvents();
        
        // Then load events
        await initializeFirebase();
        if (!db) {
            throw new Error('Firebase database not initialized');
        }
        
        console.log('Firebase initialized successfully, fetching events...');
        
        const eventsRef = collection(db, 'events');
        const q = query(eventsRef, orderBy('startDate', 'asc'));
        const querySnapshot = await getDocs(q);
        
        let eventHtml = '';
        querySnapshot.forEach((doc) => {
            const event = doc.data();
            const eventDate = event.startDate.toDate();
            
            eventHtml += `
                <div class="event-item">
                    <h3 class="event-title">${event.title}</h3>
                    <div class="event-meta">
                        <span><i class="far fa-calendar"></i> ${eventDate.toLocaleDateString()}</span>
                        <span><i class="far fa-clock"></i> ${event.time}</span>
                        <span><i class="fas fa-map-marker-alt"></i> ${event.location}</span>
                    </div>
                    <p class="event-desc">${event.description}</p>
                    ${event.locationUrl ? `<a href="${event.locationUrl}" target="_blank" class="event-location-link">View Location</a>` : ''}
                </div>
            `;
        });
        
        eventsContainer.innerHTML = eventHtml;
        
        // Handle form submission
        addEventForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            if (!auth.currentUser) {
                alert('You must be logged in to manage events');
                return;
            }

            if (!navigator.onLine) {
                alert('You are currently offline. Please try again when you have an internet connection.');
                return;
            }

            const startDate = new Date(addEventForm.date.value);
            const startTime = addEventForm.time.value.split(':');
            startDate.setHours(parseInt(startTime[0]), parseInt(startTime[1]));

            const endDate = new Date(addEventForm.endDate.value);
            const endTime = addEventForm.endTime.value.split(':');
            endDate.setHours(parseInt(endTime[0]), parseInt(endTime[1]));

            if (endDate < startDate) {
                alert('End date/time must be after start date/time');
                return;
            }

            const eventData = {
                title: addEventForm.title.value,
                description: addEventForm.description.value,
                startDate: Timestamp.fromDate(startDate),
                endDate: Timestamp.fromDate(endDate),
                time: addEventForm.time.value,
                endTime: addEventForm.endTime.value,
                location: addEventForm.location.value,
                locationUrl: addEventForm.locationUrl.value,
                recurrenceType: addEventForm.recurrenceType.value,
                updatedBy: auth.currentUser.email,
                updatedAt: Timestamp.now()
            };

            try {
                if (currentlyEditing) {
                    // Update existing event
                    await updateDoc(doc(db, 'events', currentlyEditing), eventData);
                    
                    // If it's a recurring event, update future instances
                    if (eventData.recurrenceType !== 'NONE') {
                        const futureInstances = await getDocs(
                            query(
                                collection(db, 'events'),
                                where('parentEventId', '==', currentlyEditing),
                                where('startDate', '>=', eventData.startDate)
                            )
                        );
                        
                        for (const doc of futureInstances.docs) {
                            const instance = doc.data();
                            const timeDiff = instance.startDate.toMillis() - eventData.startDate.toMillis();
                            const updatedInstance = {
                                ...eventData,
                                startDate: Timestamp.fromMillis(eventData.startDate.toMillis() + timeDiff),
                                endDate: Timestamp.fromMillis(eventData.endDate.toMillis() + timeDiff)
                            };
                            await updateDoc(doc.ref, updatedInstance);
                        }
                    }
                    
                    alert('Event updated successfully!');
                    currentlyEditing = null;
                    addEventForm.querySelector('button[type="submit"]').textContent = 'Add Event';
                } else {
                    // Add new event
                    eventData.createdBy = auth.currentUser.email;
                    eventData.createdAt = Timestamp.now();
                    await addDoc(collection(db, 'events'), eventData);
                    alert('Event added successfully!');
                }
                
                addEventForm.reset();
                await loadEvents();
            } catch (error) {
                console.error("Error managing event: ", error);
                alert('Error managing event. Please try again.');
            }
        });

        // Handle offline/online status
        window.addEventListener('online', () => {
            if (offlineWarning) {
                offlineWarning.style.display = 'none';
            }
            loadEvents();
        });

        window.addEventListener('offline', () => {
            if (offlineWarning) {
                offlineWarning.style.display = 'block';
            }
        });

    } catch (error) {
        console.error('Error fetching events:', error);
        if (eventsContainer) {
            eventsContainer.innerHTML = '<p>Error loading events. Please try again later.</p>';
        }
    }
});

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
        
        const eventsList = document.getElementById('eventsList');
        if (!eventsList) return;

        const eventsRef = collection(db, 'events');
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        const q = query(
            eventsRef, 
            where('endDate', '>=', Timestamp.fromDate(today)),
            orderBy('endDate', 'asc')
        );
        
        const querySnapshot = await getDocs(q);
        
        let eventsHtml = '';
        querySnapshot.forEach((doc) => {
            const event = doc.data();
            const startDate = event.startDate instanceof Timestamp 
                ? event.startDate.toDate() 
                : new Date(event.startDate);
            const endDate = event.endDate instanceof Timestamp 
                ? event.endDate.toDate() 
                : new Date(event.endDate);
            
            const recurrenceLabel = {
                'NONE': 'One-time',
                'WEEKLY': 'Weekly',
                'BIWEEKLY': 'Bi-weekly',
                'MONTHLY': 'Monthly',
                'FIRST_TUESDAY': 'First Tuesday'
            }[event.recurrenceType || 'NONE'];
            
            const eventUrl = getEventPage(event.title || '');
            
            eventsHtml += `
                <div class="event-item">
                    <h4>
                        <a href="${eventUrl}" class="event-title-link">
                            ${event.title}
                        </a>
                    </h4>
                    <p>Start: ${startDate.toLocaleDateString()} ${event.time || ''}</p>
                    <p>End: ${endDate.toLocaleDateString()} ${event.endTime || ''}</p>
                    <p>Location: ${event.location || 'TBD'}</p>
                    <p>Recurrence: ${recurrenceLabel}</p>
                    ${auth.currentUser ? `
                        <div class="event-actions">
                            <button onclick="editEvent('${doc.id}')" class="btn btn--stroke">Edit</button>
                            <button onclick="deleteEvent('${doc.id}')" class="btn btn--stroke">Delete</button>
                        </div>
                    ` : ''}
                </div>
            `;
        });
        
        eventsList.innerHTML = eventsHtml || '<p>No upcoming events found.</p>';
    } catch (error) {
        console.error("Error loading events: ", error);
        eventsList.innerHTML = '<p>Error loading events. Please try again.</p>';
    }
}

// Initialize offline warning display
if (document.getElementById('offlineWarning')) {
    document.getElementById('offlineWarning').style.display = navigator.onLine ? 'none' : 'block';
}
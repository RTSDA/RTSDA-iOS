import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js";
import { getFirestore, collection, addDoc } from "https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js";
import { firebaseConfig, initializeFirebase } from './firebase-config.js';

// Initialize Firebase
let db;
initializeFirebase().then(() => {
    const app = initializeApp(firebaseConfig);
    db = getFirestore(app);
}).catch(error => {
    console.error('Error initializing Firebase:', error);
});

document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('prayerRequestForm');
    const nameInput = document.getElementById('name');
    const emailInput = document.getElementById('email');
    const phoneInput = document.getElementById('phone');
    const requestInput = document.getElementById('message');
    const isPrivateCheckbox = document.getElementById('isPrivate');
    const isAnonymousCheckbox = document.getElementById('isAnonymous');
    const requestTypeSelect = document.getElementById('requestType');

    // Error message elements
    const nameError = document.getElementById('nameError');
    const emailError = document.getElementById('emailError');
    const phoneError = document.getElementById('phoneError');
    const requestError = document.getElementById('requestError');

    // Phone formatting
    phoneInput.addEventListener('input', (e) => {
        let digits = e.target.value.replace(/\D/g, '');
        if (digits.length > 10) digits = digits.substr(0, 10);
        
        let formattedNumber = '';
        if (digits.length > 0) formattedNumber += '(' + digits.substr(0, 3);
        if (digits.length > 3) formattedNumber += ') ' + digits.substr(3, 3);
        if (digits.length > 6) formattedNumber += '-' + digits.substr(6);
        
        e.target.value = formattedNumber;
    });

    // Validation functions
    const isValidEmail = (email) => {
        if (!email) return true; // Optional field
        const emailRegex = /^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$/;
        return emailRegex.test(email);
    };

    const isValidPhone = (phone) => {
        if (!phone) return true; // Optional field
        const digits = phone.replace(/\D/g, '');
        return digits.length === 10;
    };

    // Real-time validation
    nameInput.addEventListener('input', () => {
        nameError.textContent = nameInput.value ? '' : 'Please enter your name';
    });

    emailInput.addEventListener('input', () => {
        emailError.textContent = isValidEmail(emailInput.value) ? '' : 'Please enter a valid email address';
    });

    phoneInput.addEventListener('input', () => {
        phoneError.textContent = isValidPhone(phoneInput.value) ? '' : 'Please enter a valid phone number';
    });

    requestInput.addEventListener('input', () => {
        requestError.textContent = requestInput.value ? '' : 'Please enter your prayer request';
    });

    isAnonymousCheckbox.addEventListener('change', (e) => {
        const nameField = nameInput.closest('.form-field');
        if (e.target.checked) {
            nameField.style.opacity = '0.5';
            nameInput.disabled = true;
            nameInput.value = '';
            nameError.textContent = '';
            nameInput.required = false;
        } else {
            nameField.style.opacity = '1';
            nameInput.disabled = false;
            nameInput.required = true;
        }
    });

    form.addEventListener('submit', async (e) => {
        e.preventDefault();

        if (!db) {
            alert('Error: Firebase is not initialized. Please try again.');
            return;
        }

        // Validate all fields
        let isValid = true;

        if (!isAnonymousCheckbox.checked && !nameInput.value) {
            nameError.textContent = 'Please enter your name';
            isValid = false;
        }

        if (emailInput.value && !isValidEmail(emailInput.value)) {
            emailError.textContent = 'Please enter a valid email address';
            isValid = false;
        }

        if (phoneInput.value && !isValidPhone(phoneInput.value)) {
            phoneError.textContent = 'Please enter a valid phone number';
            isValid = false;
        }

        if (!requestInput.value) {
            requestError.textContent = 'Please enter your prayer request';
            isValid = false;
        }

        if (!isValid) return;

        try {
            const prayerRequest = {
                name: isAnonymousCheckbox.checked ? 'Anonymous' : nameInput.value,
                email: emailInput.value || null,
                phone: phoneInput.value || null,
                request: requestInput.value,
                timestamp: new Date(),
                status: 'new',
                isPrivate: isPrivateCheckbox.checked,
                isAnonymous: isAnonymousCheckbox.checked,
                requestType: requestTypeSelect.value
            };

            await addDoc(collection(db, 'prayerRequests'), prayerRequest);
            
            // Show success message and reset form
            alert('Prayer request submitted successfully!');
            form.reset();
            
        } catch (error) {
            console.error('Error submitting prayer request:', error);
            alert('There was an error submitting your prayer request. Please try again.');
        }
    });
});

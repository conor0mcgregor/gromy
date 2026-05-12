importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

// Tienes que poner la configuración de tu proyecto web aquí
firebase.initializeApp({
  apiKey: "AIzaSyA03ehm3pyzPi2RZvlbuJZwNShnVrUzm60",
  authDomain: "gromy-ps.firebaseapp.com",
  projectId: "gromy-ps",
  storageBucket: "gromy-ps.appspot.com",
  messagingSenderId: "G-9Z0F50SWT2",
  appId: "1:863422546089:web:384791751499e421a529b8"
});

const messaging = firebase.messaging();
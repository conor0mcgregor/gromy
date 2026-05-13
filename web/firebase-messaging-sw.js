// Estas líneas obligan al Service Worker a instalarse y activarse de inmediato
self.addEventListener('install', function(event) {
  self.skipWaiting();
});

self.addEventListener('activate', function(event) {
  event.waitUntil(clients.claim());
});

// A partir de aquí, el código que ya tenías:
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

try {
    firebase.initializeApp({
      apiKey: "AIzaSyA03ehm3pyzPi2RZvlbuJZwNShnVrUzm60",
      appId: "1:863422546089:web:384791751499e421a529b8",
      messagingSenderId: "863422546089",
      projectId: "gromy-ps",
      authDomain: "gromy-ps.firebaseapp.com",
      storageBucket: "gromy-ps.firebasestorage.app",
      measurementId: "G-9Z0F50SWT2"
    });

  const messaging = firebase.messaging();
  console.log("Service Worker de Firebase inicializado correctamente.");
} catch (error) {
  console.error("Error inicializando el Service Worker:", error);
}
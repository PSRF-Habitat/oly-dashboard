---
toc: false
---

# Olympia Oysters! 🦪

---
<!-- ===================================================== -->
<!-- Page grid layout -->
<!-- ===================================================== -->
<div class="grid grid-cols-2">
  
  <!-- Map card -->
  <div class="card grid-rowspan-2">
    <div id="map"></div>
  </div>
  
  <!-- Text card --> 
  <div class="card">

## Text goes here

  </div>
  
  <!-- Plot card --> 
  <div class="card">

## Data Vis here

  </div>
  
</div> <!-- END Page grid -->

<!-- ===================================================== -->
<!-- Build Map -->
<!-- ===================================================== -->

```js
// Load enhancement map data
const enh_sites = await FileAttachment("data/enhancements.csv").csv({typed: true});

// Load Leaflet library
import * as L from "npm:leaflet@1.9.4";

// Salish Sea coordinates
const center = [47.8, -123.5];
const zoom = 8;

// Create map
const map = L.map("map", {
  center: center,
  zoom: zoom,
  zoomControl: true,
  scrollWheelZoom: true,
  attributionControl: false
});

// CartoDB Positron Basemap (light, clean style)
L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
  attribution: '© OpenStreetMap © CartoDB',
  maxZoom: 20
}).addTo(map);

// Alternative basemap options:

// Add OpenStreetMap tile layer (classic. busy.)
// L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
//   attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
//   maxZoom: 19
// }).addTo(map);

// Esri World Imagery (satellite)
// L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
//   attribution: 'Tiles © Esri'
// }).addTo(map);

// Esri Ocean Basemap (soft, marine colors. no place names)
// L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/Ocean/World_Ocean_Base/MapServer/tile/{z}/{y}/{x}', {
//   attribution: 'Tiles © Esri'
// }).addTo(map);

// Add markers
enh_sites.forEach(site => {
  console.log(`Lat: ${site.enhancement_latitude_est}, Lng: ${site.enhancement_longitude_est}`);
  const marker = L.marker([site.enhancement_latitude_est, site.enhancement_longitude_est]).bindPopup(`
      <strong>${site.site_name}</strong><br>
      Type: ${site.enhancement_type}<br>
      Years: ${site.enhancement_years}
    `)
    .addTo(map);
});

// Add a scale bar
L.control.scale({imperial: true, metric: true}).addTo(map);

// Allow page to render before loading map details
setTimeout(() => map.invalidateSize(), 100);
```

<!-- Style Map -->
<!-- Load Leaflet's required CSS -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/leaflet@1.9.4/dist/leaflet.css" /> 

<style>
  #map {
    width: 100%;
    height: 700px;
    border-radius: 8px;
    overflow: hidden;
  }
  
  /* Inheret map font from main page styles */
  .leaflet-container {
    font-family: inherit; 
  }
</style>
<!-- END map build -->
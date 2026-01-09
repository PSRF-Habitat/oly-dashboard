---
toc: false
title: "Full page map with Observable Plot"
theme: dashboard
header: "<a href='https://restorationfund.org'><img src='data/images/logo-transwhite.png' alt='Logo' style='height: 120px;'></a>"
pager: false
---
<!-- =================================================== -->
<!-- Header bar syling -->
<!-- =================================================== -->
<style>
#observablehq-header {
  position: absolute;
  background-color: #045B4C;
  height: 150px;
  align-items: center;
  padding: 0 30px;
}

#observablehq-footer {
  position: absolute;
  background-color: #5A5A5A;
  align-items: center;
  width: 100%;
  left: 0;
  padding: 0 30px;
  box-sizing: border-box;
}

/* Add space below header so content doesn't overlap */
body {
  padding-top: 80px;
  padding-left: 40px;
  padding-right:40px;
}
</style>

<!-- =================================================== -->
<!-- Cards with flashy facts -->
<!-- =================================================== -->
<div class="grid grid-cols-4" style="text-align: center;">
  <div class="card">
    <h1 class="muted">Acres Restored</h1>
    <span class = "big" style="color: #045B4C">141.3</span>
  </div>
  <div class="card" style="text-align: center;">
    <h1 class="muted">Sites Visited</h1>
    <span class = "big" style="color: #045B4C">777</span>
  </div>
  <div class="card" style="text-align: center;">
    <h1 class="muted">Some Other</h1>
    <span class = "big" style="color: #045B4C">222</span>
  </div>
  <div class="card" style="text-align: center;">
    <h1 class="muted">Catchy Facts</h1>
    <span class = "big" style="color: #045B4C">999</span>
  </div>
</div>

---

<!-- =================================================== -->
<!-- Big 'ol Map! -->
<!-- =================================================== -->

```js
// ===================================================
// Setup
// ===================================================

// Load the enhancement sites CSV 
const enh_sites = await FileAttachment("data/enhancements.csv").csv({typed: true});

// Load the recruitment sites CSV
const recruit_sites = await FileAttachment("data/recruitment_station_info.csv").csv({typed: true});

// Load oyster population assessment CSV
const ann_densities = await FileAttachment("data/assessments.csv").csv({typed: true});

// Import required libraries
import * as L from "npm:leaflet@1.9.4";  // Leaflet for map
import * as Plot from "npm:@observablehq/plot"; // Observable Plot

// ===================================================
// Global State Management
// These variables track the current state across map and plot
// ===================================================

// Track which location is currently being hovered over
window.highlightedLocation = null;

// Track which site is currently selected/clicked (so it can stay highlighted)
window.selectedSite = null;

// ===================================================
// Map Configuration
// ===================================================

// Center point for map loading (Puget Sound area)
const center = [47.85, -122.7];

// Initial zoom level
const zoom = 9;

// Define tooltip photos for each site
const tooltipPhotos = {
  "Port Gamble Bay": FileAttachment("data/images/port_gamble_SAMPLE_tooltip.jpg").href,
  "Quilcene Bay": FileAttachment("data/images/quilcene_SAMPLE_tooltip.jpg").href,
  "Sinclair Inlet": FileAttachment("data/images/sinclair_SAMPLE_tooltip.jpg").href,
  "Legion Park": FileAttachment("data/images/legion_SAMPLE_tooltip.jpg").href
};

// ===================================================
// Marker Icons for Map
// Different shapes for different data types
// Make these custom drawn later? 
// ===================================================

// Blue circle for enhancement sites
const enhancementIcon = L.divIcon({
  className: 'custom-marker',
  html: `<div style="
    background-color: #4e79a7;
    width: 14px;
    height: 14px;
    border-radius: 50%;
    border: 2px solid white;
    box-shadow: 0 0 4px rgba(0,0,0,0.4);
  "></div>`,
  iconSize: [18, 18],
  iconAnchor: [9, 9]
});

// Red triangle for recruitment sites
const recruitmentIcon = L.divIcon({
  className: 'custom-marker',
  html: `<div style="
    width: 0;
    height: 0;
    border-left: 8px solid transparent;
    border-right: 8px solid transparent;
    border-bottom: 14px solid #e15759;
    filter: drop-shadow(0 0 3px rgba(0,0,0,0.4));
  "></div>`,
  iconSize: [16, 16],
  iconAnchor: [8, 14]
});

// ===================================================
// FILTER PANEL COMPONENT
// This creates the filter controls that will go in the left card
// ===================================================
function createFilterPanel(enhancementLayer, recruitmentLayer) {
  const panel = document.createElement("div");
  
  panel.innerHTML = `
    <div style="padding: 10px;">
      <h3 style="margin-top: 0; margin-bottom: 15px; color: #045B4C;">Map Filters</h3>
      
      <div style="margin-bottom: 15px;">
        <label style="display: flex; align-items: center; cursor: pointer; padding: 8px; border-radius: 4px; transition: background 0.2s;">
          <input type="checkbox" id="enhancement-toggle" checked style="margin-right: 10px; cursor: pointer; width: 18px; height: 18px;">
          <span style="display: flex; align-items: center; gap: 8px;">
            <div style="
              background-color: #4e79a7;
              width: 14px;
              height: 14px;
              border-radius: 50%;
              border: 2px solid white;
              box-shadow: 0 0 3px rgba(0,0,0,0.3);
            "></div>
            Enhancement Sites
          </span>
        </label>
      </div>
      
      <div style="margin-bottom: 15px;">
        <label style="display: flex; align-items: center; cursor: pointer; padding: 8px; border-radius: 4px; transition: background 0.2s;">
          <input type="checkbox" id="recruitment-toggle" checked style="margin-right: 10px; cursor: pointer; width: 18px; height: 18px;">
          <span style="display: flex; align-items: center; gap: 8px;">
            <div style="
              width: 0;
              height: 0;
              border-left: 7px solid transparent;
              border-right: 7px solid transparent;
              border-bottom: 12px solid #e15759;
              margin-left: 3px;
            "></div>
            Recruitment Sites
          </span>
        </label>
      </div>
      
      <hr style="border: none; border-top: 1px solid #ddd; margin: 20px 0;">
      
      <div style="color: #666; font-size: 14px;">
        <p style="margin: 5px 0;"><strong>Potential Filters to Add:</strong></p>
        <ul style="margin: 10px 0; padding-left: 20px; font-size: 13px;">
          <li>Enhancement type</li>
          <li>Site drop down</li>
        </ul>
      </div>
    </div>
  `;
  
  // Add event listeners for the checkboxes
  const enhToggle = panel.querySelector('#enhancement-toggle');
  const recToggle = panel.querySelector('#recruitment-toggle');
  
  enhToggle.addEventListener('change', (e) => {
    if (e.target.checked) {
      enhancementLayer.addTo(enhancementLayer._map);
    } else {
      enhancementLayer.remove();
    }
  });
  
  recToggle.addEventListener('change', (e) => {
    if (e.target.checked) {
      recruitmentLayer.addTo(recruitmentLayer._map);
    } else {
      recruitmentLayer.remove();
    }
  });
  
  return panel;
}

// ===================================================
// MAIN MAP FUNCTION
// This creates the entire map and detail panels with plots embedded
// ===================================================
function oysterMap(enhData, recruitData, densityData, {width} = {}) {
  // Create the main container that holds both map and story panel
  const mainContainer = document.createElement("div");

  Object.assign(mainContainer.style, {
    width: `${width}px`,
    height: "90vh",
    minHeight: "600px", // Ensure it doesn't get too small
  });

  // Container for the leaflet map
  const mapContainer = document.createElement("div");
  Object.assign(mapContainer.style, {
    width: "100%",
    height: "100%",
    borderRadius: "8px",
    transition: "all 0.25s ease-in-out"
  });

  // Container for the story panel, hidden by default
  const detailContainer = document.createElement("div");
  Object.assign(detailContainer.style, {
    display: "none",  // Hide initially
    width: "60%",    // Take 60% of main container when shown
    height: "100%",
    padding: "20px",
    backgroundColor: "white",
    borderRadius: "8px",
    transition: "all 1s ease-in-out",
    opacity: "0",
    overflowY: "auto",     // Scrollable
    overflowX: "hidden",   // No horizontal scrolling
    boxSizing: "border-box"
  });

  // Add both containers to main container
  mainContainer.appendChild(mapContainer);
  mainContainer.appendChild(detailContainer);

  // Initialize the Leaflet map
  const map = L.map(mapContainer, { center, zoom });
  
  // Add basemap tiles
  L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
    attribution: '© OpenStreetMap © CartoDB',
    maxZoom: 15
  }).addTo(map);
  
  // ===================================================
  // Create Layer Groups
  // Separate layers to toggle different data types on/off
  // ===================================================
  const enhancementLayer = L.layerGroup().addTo(map);
  const recruitmentLayer = L.layerGroup().addTo(map);
  
  // Global object to store marker references by site name
  // This allows us to access markers from other functions (like the plot)
  window.markersBySite = {};

  // ===================================================
  // SHOW DETAIL PANEL FUNCTION
  // Called when user clicks on an enhancement site
  // ===================================================
  function showDetail(site) {
    // Set this site as the selected site
    window.selectedSite = site.site_name;
    
    // Rearrange layout so map moves to left when story panel opens on right
    mainContainer.style.display = "flex";
    mainContainer.style.gap = "10px";
    mapContainer.style.width = "40%";
    mapContainer.style.flexShrink = "0";
    detailContainer.style.display = "block";  // Show detail panel

    // Fade in the detail panel (short delay to allow things to load)
    setTimeout(() => detailContainer.style.opacity = "1", 10);

    // Resize map and zoom to selected site location
    setTimeout(() => {
      map.invalidateSize(); // Tell Leaflet that the container size changed
      map.setView([site.enhancement_latitude_est, site.enhancement_longitude_est], 12, {animate: false});
    }, 250);
    
    // Create back button to return to full map view
    const backButton = document.createElement("button");
    backButton.textContent = "← Back to Map";
    Object.assign(backButton.style, {
      marginBottom: "20px",
      padding: "8px 16px",
      cursor: "pointer",
      border: "1px solid #ccc",
      borderRadius: "4px",
      backgroundColor: "#f5f5f5"
    });
    backButton.onclick = resetView; // Clicking on button resets view

    // Clear any previous story content
    detailContainer.innerHTML = "";
    detailContainer.appendChild(backButton);

    // Get tooltip photo if it exists, otherwise use empty array
    const photos = tooltipPhotos[site.site_name] ? [tooltipPhotos[site.site_name]] : [];

    // Define additional images for sites
    // UPDATE as more are added!!! SAMPLE IMAGES FOR NOW!!!
    const additionalImages = {
  "Port Gamble Bay": [
    FileAttachment("data/images/oly_sample_pic.jpg").href,
    FileAttachment("data/images/beach_sample_pic.jpg").href
  ],
  "Quilcene Bay": [
    FileAttachment("data/images/oly_sample_pic.jpg").href,
    FileAttachment("data/images/beach_sample_pic.jpg").href
  ]
};

   // Combine tooltip photo with any additional images
    const allPhotos = [...photos, ...(additionalImages[site.site_name] || [])].filter(Boolean);

    // Create section ("div") for site story info
    const content = document.createElement("div");

    // Build photo carousel if site has photos
    const carouselHTML = photos.length > 0 ? `
      <div class="carousel">
        <button class="carousel-btn prev">‹</button>
        <div class="carousel-images">
          ${allPhotos.map((url, i) => 
            `<img src="${url}" class="carousel-image ${i === 0 ? 'active' : ''}">`
          ).join('')}
        </div>
        <button class="carousel-btn next">›</button>
        <div class="carousel-dots"></div>
      </div>
    ` : '';

    // Build the full detail panel content
    content.innerHTML = `
      <h2>${site.site_name}</h2>
      ${carouselHTML}
      <h3>About this site</h3>
      <p>Story about the site</p>
      <h3>Population Density Over Time</h3>
      <div id="density-plot-container"></div>
    `;
    
    detailContainer.appendChild(content);
  
    // ===================================================
    // Carousel Functionality
    // ===================================================
    if (allPhotos.length > 0) {
      const images = content.querySelectorAll('.carousel-image');
      const dotsContainer = content.querySelector('.carousel-dots');
      let currentIndex = 0;  // Track which image is currently shown
    
      // Create navigation dots (one per image)
      images.forEach((_, index) => {
        const dot = document.createElement('span');
        dot.className = 'carousel-dot' + (index === 0 ? ' active' : '');
        dot.onclick = () => showImage(index); // Clicking dot jumps to that image
        dotsContainer.appendChild(dot);
      });
    
      const dots = content.querySelectorAll('.carousel-dot');
    
      // Function to switch to a specific image
      function showImage(index) {
        images[currentIndex].classList.remove('active');  // Hide current image
        dots[currentIndex].classList.remove('active');   // Deactivate current dot
        currentIndex = index;   // Update index
        images[currentIndex].classList.add('active');   // Show new image
        dots[currentIndex].classList.add('active');    // Activate new dot
      }
      
      // Previous button: go to previous image (wraps around)
      content.querySelector('.prev').onclick = () => {
        showImage((currentIndex - 1 + images.length) % images.length);
      };
      
      // Next button: go to next image (wraps around)
      content.querySelector('.next').onclick = () => {
        showImage((currentIndex + 1) % images.length);
      };
    }

    // ===================================================
    // Create Oyster Density Plot
    // ===================================================
    const plotContainer = content.querySelector('#density-plot-container');
    plotContainer.appendChild(
    createDensityPlot(densityData, site.site_name)
    );
  }

  // ===================================================
  // RESET VIEW FUNCTION
  // Returns to full map view, closing detail panel
  // ===================================================
  function resetView() {
    // Clear the selected site
    window.selectedSite = null;

    // Fade out story container
    detailContainer.style.opacity = "0";

    setTimeout(() => {
      // Reset to single column layout so map is full width
      mainContainer.style.display = "block";
      Object.assign(mapContainer.style, {
        width: "100%",
        height: "100%"
      });
      detailContainer.style.display = "none"; // Hide detail panel

      setTimeout(() => {
        // Resize map back to full size and reset zoom
        map.invalidateSize();
        map.setView(center, zoom, {animate: false});
      }, 250);
    }, 250);
  }

// ===================================================
// ADD RECRUITMENT MARKERS
// Loop through all recruitment sites and add TRIANGLE markers
// ===================================================
recruitData.forEach(site => {
  // Skip if coordinates are missing or NA
  if (!site.latitude || !site.longitude || 
      site.latitude === 'NA' || site.longitude === 'NA' ||
      isNaN(parseFloat(site.latitude)) || isNaN(parseFloat(site.longitude))) {
    return;
  }
  
  // Create Recruitment Markers + Tooltips
  const marker = L.marker(
    [parseFloat(site.latitude), parseFloat(site.longitude)],  // Ensure numbers
    { icon: recruitmentIcon }
  )
  .bindTooltip(`
    <strong>${site.standard_station}</strong><br>
    Type: Recruitment Monitoring<br>
    Years: years here
  `, {
    direction: 'top',
    permanent: false
  })
  .addTo(recruitmentLayer);
  
  // Store marker reference with prefix to avoid naming conflicts
  window.markersBySite[site.standard_station] = marker;
});
  
  // ===================================================
  // ADD ENHANCEMENT MARKERS
  // ===================================================
  enhData.forEach(site => {
    // Create marker at site coordinates with CIRCLE icon
    const marker = L.marker(
      [site.enhancement_latitude_est, site.enhancement_longitude_est],
      { icon: enhancementIcon }  // Blue circle
    )
    .bindTooltip(() => {
  const photoUrl = tooltipPhotos[site.site_name];
  const photoHTML = photoUrl ? `
    <img src="${photoUrl}" style="
      width: 100%;
      height: 120px;
      object-fit: cover;
      border-radius: 4px;
      border: 2px solid #ddd;
      margin-top: 8px;
      margin-bottom: 8px;
    ">
  ` : '';
  
  return `
    <div style="min-width: 200px; padding: 12px;">
      <div style="
        font-size: 16px;
        font-weight: bold;
        text-align: center;
        margin-bottom: 4px;
      ">
        ${site.site_name}
      </div>
      ${photoHTML}
      <div style="font-size: 12px; margin-top: 4px;">
        Type: ${site.enhancement_type}<br>
        Years: ${site.enhancement_years}
        <em style="color: #007bff; font-size: 11px;">▶ Click for more details</em>
      </div>
    </div>
  `;
}, {
  direction: 'top',
  permanent: false,
  className: 'custom-tooltip'
})
    .addTo(enhancementLayer);  // Add to enhancement layer (not directly to map)
  
    // Store marker reference for access from plot interactions
    window.markersBySite[site.site_name] = marker;

   // Pop up panel on click
    marker.on('click', () => {
        showDetail(site);
    });
  });

  
  // ===================================================
  // ADD LAYER CONTROL
  // This creates the checkbox to toggle layers on/off
  // ===================================================
//   const overlays = {
//     "Enhancement Sites": enhancementLayer,
//     "Recruitment Sites": recruitmentLayer
//   };
  
//   L.control.layers(null, overlays, {
//     collapsed: false,  // Keep it expanded so users see it
//     position: 'topright'
//   }).addTo(map);

  // ===================================================
  // ADD LEGEND
  // Shows what each marker shape/color means
  // ===================================================
  const legend = L.control({position: 'topright'});

  legend.onAdd = function(map) {
    const div = L.DomUtil.create('div', 'map-legend');
    div.innerHTML = `
      <div style="
        background: white;
        padding: 10px;
        border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.15);
        font-size: 13px;
      ">
        <div style="margin-bottom: 5px;"><strong>Site Types</strong></div>
        <div style="display: flex; align-items: center; margin: 5px 0;">
          <div style="
            background-color: #4e79a7;
            width: 14px;
            height: 14px;
            border-radius: 50%;
            border: 2px solid white;
            margin-right: 8px;
          "></div>
          Enhancement
        </div>
        <div style="display: flex; align-items: center; margin: 5px 0;">
          <div style="
            width: 0;
            height: 0;
            border-left: 7px solid transparent;
            border-right: 7px solid transparent;
            border-bottom: 12px solid #e15759;
            margin-right: 8px;
            margin-left: 3px;
          "></div>
          Recruitment
        </div>
      </div>
    `;
    return div;
  };

  legend.addTo(map);
  
  // Add scalebars
  L.control.scale({imperial: true, metric: true}).addTo(map);

 // Simple resize handler for when window size changes
  const handleResize = () => {
    setTimeout(() => map.invalidateSize(), 100);
  };
  
  window.addEventListener('resize', handleResize);
  
  // Small delay to allow data to load before rendering map
  setTimeout(() => map.invalidateSize(), 100);

   // Store the layers on the main container so we can access them later
  mainContainer._enhancementLayer = enhancementLayer;
  mainContainer._recruitmentLayer = recruitmentLayer;
  
  return mainContainer;
}

// ===================================================
// DENSITY PLOT FUNCTION FOR SIDEBAR
// This creates a plot that highlights the selected site
// ===================================================
function createDensityPlot(data, selectedSite) {
  return Plot.plot({
    height: 350,
    marginLeft: 50,
    marginRight: 50,
    marginTop: 30,
    marginBottom: 40,
    x: {
      label: "Year",
      tickFormat: "d"
    },
    y: {
      label: "Density (m⁻²)",
      grid: true
    },
    marks: [
      // Gray background lines for all sites
      Plot.line(data, {
        x: "year",
        y: "density",
        z: "location",
        stroke: "#ddd",
        strokeWidth: 2
      }),
      // Gray dots for all sites
      Plot.dot(data, {
        x: "year",
        y: "density",
        fill: "#ddd",
        stroke: "white",
        strokeWidth: 1.5,
        r: 4
      }),
      // Colored line for selected site
      Plot.line(
        data.filter(d => d.location === selectedSite),
        {
          x: "year",
          y: "density",
          stroke: "#4e79a7",
          strokeWidth: 3
        }
      ),
      // Colored dots for selected site
      Plot.dot(
        data.filter(d => d.location === selectedSite),
        {
          x: "year",
          y: "density",
          fill: "#4e79a7",
          stroke: "white",
          strokeWidth: 2,
          r: 5
        }
      ),
      // Tooltip for interactivity
      Plot.tip(data, Plot.pointer({
        x: "year",
        y: "density",
        title: d => `${d.location}, ${d.year}: ${d.density.toFixed(2)} m⁻²`
      }))
    ]
  });
}

window.addEventListener('resize', () => {
  const map = document.querySelector('.leaflet-container');
  if (map && map._leaflet_map) {
    map._leaflet_map.invalidateSize();
  }
});


const mapInstance = resize((width) => {
  const container = oysterMap(enh_sites, recruit_sites, ann_densities, {width});
  // Store reference globally so filter panel can access it
  window.currentMapInstance = container;
  return container;
});

```

<!-- Link to Leaflet CSS -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/leaflet@1.9.4/dist/leaflet.css" /> 

<!-- ===================================================== -->
<!-- CUSTOM STYLES -->
<!-- ===================================================== -->
<style>  
  .leaflet-container { font-family: inherit; }

  .leaflet-control-attribution {
    background-color: rgba(255, 255, 255, 0.7);
    font-size: 10px; 
    opacity: 0.6;
    padding: 2px 5px;
  }
  .leaflet-control-attribution:hover { opacity: 1; }
  
  /* CAROUSEL STYLES */
  .carousel {
    position: relative;
    width: 100%;
    margin: 20px 0;
    background: #f5f5f5;
    border-radius: 8px;
    overflow: hidden;
  }
  .carousel-images {
    position: relative;
    width: 100%;
    padding-bottom: 66%;
  }
  .carousel-image {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: contain;
    opacity: 0;
    transition: opacity 0.3s ease;
    pointer-events: none;
    background: #f5f5f5;
  }
  .carousel-image.active {
    opacity: 1;
    pointer-events: auto;
  }
  .carousel-btn {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    background: rgba(255, 255, 255, 0.8);
    border: none;
    font-size: 32px;
    padding: 8px 10px;
    cursor: pointer;
    z-index: 10;
    border-radius: 4px;
    transition: background 0.2s ease;
  }
  .carousel-btn:hover { background: rgba(255, 255, 255, 1); }
  .carousel-btn.prev { left: 10px; }
  .carousel-btn.next { right: 10px; }
  .carousel-dots {
    position: absolute;
    bottom: 10px;
    left: 50%;
    transform: translateX(-50%);
    display: flex;
    gap: 8px;
    z-index: 10;
  }
  .carousel-dot {
    width: 10px;
    height: 10px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.5);
    cursor: pointer;
    transition: background 0.2s ease;
  }
  .carousel-dot.active { background: rgba(255, 255, 255, 1); }
  .carousel-dot:hover { background: rgba(255, 255, 255, 0.8); }

  /* Custom tooltip styling */
  .custom-tooltip {
    padding: 0 !important;
    box-shadow: 0 2px 8px rgba(0,0,0,0.15);
  }

  .custom-tooltip .leaflet-tooltip-content {
    padding: 0 !important;
    margin: 0;
  }

  .custom-tooltip img {
    display: block;
    background: #f0f0f0;
  }
  
    #density-plot-container {
    width: 100%;
    }

</style>


<!-- Display Map in Card -->
<div class="grid grid-cols-4">
  <div class="card">
    <h2 style="margin-top: 0;">Filters</h2>
    ${(function() {
      // Wait for map to load, then create filter panel
      setTimeout(() => {
        const container = document.querySelector('#filter-container');
        if (window.currentMapInstance && container) {
          container.appendChild(
            createFilterPanel(
              window.currentMapInstance._enhancementLayer,
              window.currentMapInstance._recruitmentLayer
            )
          );
        }
      }, 500);
      const div = document.createElement('div');
      div.id = 'filter-container';
      return div;
    })()}
  </div>

  <div class="card grid-colspan-3">
    ${mapInstance}
  </div>
</div>

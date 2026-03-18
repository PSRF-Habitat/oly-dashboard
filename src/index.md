---
toc: false
title: "Full page map with Filter Panel"
theme: dashboard
header: "<a href='https://restorationfund.org'><img src='data/images/logo-transwhite.png' alt='Logo' style='height: 120px;'></a>"
pager: false
---
<!-- =================================================== -->
<!-- Header & footer syling -->
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

/* Add space below header so page content doesn't overlap */
body {
  padding-top: 80px;
  padding-left: 40px;
  padding-right:40px;
}
</style>
<!-- =================================================== -->
<!-- END Header & footer syling -->
<!-- =================================================== -->

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
<!-- =================================================== -->
<!-- END Cards with flashy facts -->
<!-- =================================================== -->

---

<!-- =================================================== -->
<!-- Big Map! -->
<!-- =================================================== -->

```js
// ===================================================
// Setup
// ===================================================

// Load the enhancement sites metadata CSV
const enh_sites_metadata = await FileAttachment("data/enhancement_sites_metadata.csv").csv({typed: true});

// Load the recruitment sites CSV
const recruit_sites = await FileAttachment("data/recruitment_station_info.csv").csv({typed: true});

// Load oyster population assessment CSV
const ann_densities = await FileAttachment("data/assessments.csv").csv({typed: true});

// Load timeline data CSV
const timeline_data = await FileAttachment("data/timeline_data.csv").csv({typed: true});

// Store globally for timeline function
window.timelineData = timeline_data;

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
const zoom = 8;

// Define tooltip photos for each site
const tooltipPhotos = {
  "Port Gamble Bay": FileAttachment("data/images/port_gamble_SAMPLE_tooltip.jpg").href,
  "Quilcene Bay": FileAttachment("data/images/quilcene_SAMPLE_tooltip.jpg").href,
  "Sinclair Inlet": FileAttachment("data/images/sinclair_SAMPLE_tooltip.jpg").href,
  "Legion Park": FileAttachment("data/images/legion_SAMPLE_tooltip.jpg").href,
  "Fidalgo Bay": FileAttachment("data/images/fidalgo_tooltip.jpeg").href
};

// ===================================================
// Marker Icons for Map
// Different shapes for different data types
// Placeholder for custom drawn later
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
function createFilterPanel(enhancementLayer, recruitmentLayer, map, enhData) {
  let currentOpenMarker = null;  // track currently open tooltip marker

  const panel = document.createElement("div");
  
  panel.innerHTML = `
    <div style="padding: 0;">
      
      <!-- Instructions: Control What You See -->
      <div style="
        background: linear-gradient(135deg, #f0f7f6 0%, #e8f4f2 100%);
        padding: 16px;
        border-radius: 6px;
        border-left: 4px solid #045B4C;
        margin-bottom: 24px;
      ">
        <div style="
          font-size: 12px;
          font-weight: 600;
          color: #045B4C;
          margin-bottom: 10px;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        ">Customize Your View</div>
        <div style="
          font-size: 13px;
          color: #555;
          line-height: 1.7;
        ">
          <p style="margin: 0;">
            Use the controls below to filter the map
          </p>
        </div>
      </div>
      
      <!-- Map Layers Section -->
      <div style="margin-bottom: 20px;">
        <label style="
          display: block;
          font-size: 13px;
          font-weight: 600;
          color: #045B4C;
          margin-bottom: 12px;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        ">Map Layers</label>
        
        <!-- Enhancement Sites Toggle -->
        <label class="filter-checkbox-label" style="
          display: flex;
          align-items: center;
          cursor: pointer;
          padding: 8px 10px;
          border-radius: 6px;
          transition: background 0.2s ease;
          margin-bottom: 6px;
          background: #f8f9fa;
        ">
          <input 
            type="checkbox" 
            id="enhancement-toggle" 
            checked 
            style="
              margin-right: 10px;
              cursor: pointer;
              width: 16px;
              height: 16px;
              accent-color: #045B4C;
            "
          >
          <span style="display: flex; align-items: center; gap: 8px; flex: 1;">
            <div style="
              background-color: #4e79a7;
              width: 14px;
              height: 14px;
              border-radius: 50%;
              border: 2px solid white;
              box-shadow: 0 2px 4px rgba(0,0,0,0.2);
              flex-shrink: 0;
            "></div>
            <span style="font-size: 13px; color: #333; font-weight: 500;">
              Restoration Enhancements
            </span>
          </span>
        </label>
        
        <!-- Recruitment Sites Toggle -->
        <label class="filter-checkbox-label" style="
          display: flex;
          align-items: center;
          cursor: pointer;
          padding: 8px 10px;
          border-radius: 6px;
          transition: background 0.2s ease;
          margin-bottom: 6px;
          background: #f8f9fa;
        ">
          <input 
            type="checkbox" 
            id="recruitment-toggle" 
            checked
            style="
              margin-right: 10px;
              cursor: pointer;
              width: 16px;
              height: 16px;
              accent-color: #045B4C;
            "
          >
          <span style="display: flex; align-items: center; gap: 8px; flex: 1;">
            <div style="
              width: 0;
              height: 0;
              border-left: 7px solid transparent;
              border-right: 7px solid transparent;
              border-bottom: 12px solid #e15759;
              margin-left: 3px;
              flex-shrink: 0;
            "></div>
            <span style="font-size: 13px; color: #333; font-weight: 500;">
              Recruitment Monitoring
            </span>
          </span>
        </label>
        
        <div style="
          font-size: 11px;
          color: #666;
          margin-top: 10px;
          padding-left: 4px;
          font-style: italic;
        ">
          Show or hide data types
        </div>
      </div>
      
      <!-- Divider -->
      <div style="
        height: 1px;
        background: linear-gradient(to right, transparent, #ddd, transparent);
        margin: 24px 0;
      "></div>
      
      <!-- Enhancement Type Filter Section -->
      <div style="margin-bottom: 20px;">
        <label style="
          display: block;
          font-size: 13px;
          font-weight: 600;
          color: #045B4C;
          margin-bottom: 8px;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        ">Filter by Enhancement Type</label>
        
        <div style="display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 8px;">
          <button 
            class="type-toggle-btn" 
            data-type="bulk shell"
            style="
              padding: 8px 16px;
              border: 2px solid #045B4C;
              border-radius: 20px;
              background: #045B4C;
              color: white;
              font-size: 13px;
              font-weight: 500;
              cursor: pointer;
              transition: all 0.2s ease;
              white-space: nowrap;
            "
          >Bulk Shell</button>
          
          <button 
            class="type-toggle-btn" 
            data-type="seeded cultch"
            style="
              padding: 8px 16px;
              border: 2px solid #045B4C;
              border-radius: 20px;
              background: #045B4C;
              color: white;
              font-size: 13px;
              font-weight: 500;
              cursor: pointer;
              transition: all 0.2s ease;
              white-space: nowrap;
            "
          >Seeded Cultch</button>
          
          <button 
            class="type-toggle-btn" 
            data-type="singles"
            style="
              padding: 8px 16px;
              border: 2px solid #045B4C;
              border-radius: 20px;
              background: #045B4C;
              color: white;
              font-size: 13px;
              font-weight: 500;
              cursor: pointer;
              transition: all 0.2s ease;
              white-space: nowrap;
            "
          >Singles</button>
        </div>
        
        <div style="
          font-size: 11px;
          color: #666;
          margin-top: 6px;
          font-style: italic;
        ">
          Select which enhancement methods are displayed
        </div>
      </div>
      
      <!-- Divider -->
      <div style="
        height: 1px;
        background: linear-gradient(to right, transparent, #ddd, transparent);
        margin: 24px 0;
      "></div>
      
      <!-- Instructions: Navigate the Map -->
      <div style="
        background: linear-gradient(135deg, #f0f7f6 0%, #e8f4f2 100%);
        padding: 16px;
        border-radius: 6px;
        border-left: 4px solid #045B4C;
        margin-bottom: 24px;
      ">
        <div style="
          font-size: 12px;
          font-weight: 600;
          color: #045B4C;
          margin-bottom: 10px;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        ">Navigate the Map</div>
        <div style="
          font-size: 13px;
          color: #555;
          line-height: 1.7;
        ">
          <p style="margin: 0 0 10px 0;">
            <strong style="color: #045B4C;">Pan and Zoom:</strong> Click and drag to explore, scroll to zoom in and out
          </p>
          <p style="margin: 0;">
            <strong style="color: #045B4C;">Quick Jump:</strong> Use the dropdown below to jump directly to a specific site
          </p>
        </div>
      </div>
      
      <!-- Site Selector Section -->
      <div style="margin-bottom: 24px;">
        <label style="
          display: block;
          font-size: 13px;
          font-weight: 600;
          color: #045B4C;
          margin-bottom: 8px;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        ">Jump to Site</label>
        <select id="site-selector" style="
          width: 100%;
          padding: 10px 12px;
          border: 2px solid #e0e0e0;
          border-radius: 6px;
          font-size: 14px;
          background: white;
          cursor: pointer;
          transition: all 0.2s ease;
          color: #333;
        ">
          <option value="">Select a site...</option>
        </select>
        <div style="
          font-size: 11px;
          color: #666;
          margin-top: 6px;
          font-style: italic;
        ">
          Zoom to a site and view its details
        </div>
      </div>
      
    </div>
  `;
  
  // Populate site selector dropdown
  const siteSelector = panel.querySelector('#site-selector');
  
  // Get unique sites with spatial data and sort alphabetically
  const uniqueSites = [...new Set(
  enhData
    .filter(site => 
      site.latitude && site.longitude &&
      site.latitude !== 'NA' && site.longitude !== 'NA' &&
      !isNaN(parseFloat(site.latitude)) && !isNaN(parseFloat(site.longitude))
    )
    .map(site => site.site_name)
  )].sort();
  
  uniqueSites.forEach(siteName => {
    const option = document.createElement('option');
    option.value = siteName;
    option.textContent = siteName;
    siteSelector.appendChild(option);
  });
  
  // Site selector change event - zoom and show tooltip
  siteSelector.addEventListener('change', (e) => {
    const selectedSite = e.target.value;
    if (selectedSite && window.markersBySite[selectedSite]) {
      const marker = window.markersBySite[selectedSite];
      const latLng = marker.getLatLng();

      // Close previous tooltip explicitly instead of map.closeTooltip()
      if (currentOpenMarker) {
        currentOpenMarker.closeTooltip();
      }
      
      // Zoom to site and show tooltip
      map.setView(latLng, 12, { animate: true, duration: 0.5 });
      
      // Open tooltip after zoom
      setTimeout(() => {
        marker.openTooltip();
        currentOpenMarker = marker;  // track this as the now-open marker
      }, 600);
    }
  });

  // Clear dropdown selection when user zooms out
  map.on('zoomend', () => {
    const currentZoom = map.getZoom();
     // If zoomed out beyond a threshold (e.g., below zoom level 11), clear selection
    if (currentZoom < 11) {
      siteSelector.value = '';
   }
  });
  
  // Enhancement toggle event
  const enhToggle = panel.querySelector('#enhancement-toggle');
  enhToggle.addEventListener('change', (e) => {
    if (e.target.checked) {
      enhancementLayer.addTo(map);
    } else {
      enhancementLayer.remove();
    }
  });
  
  // Recruitment toggle event
  const recToggle = panel.querySelector('#recruitment-toggle');
  recToggle.addEventListener('change', (e) => {
    if (e.target.checked) {
      recruitmentLayer.addTo(map);
    } else {
      recruitmentLayer.remove();
    }
  });
  
  // Add hover effects to checkbox labels
  const labels = panel.querySelectorAll('.filter-checkbox-label');
  labels.forEach(label => {
    label.addEventListener('mouseenter', () => {
      label.style.background = '#e8f4f2';
    });
    label.addEventListener('mouseleave', () => {
      label.style.background = '#f8f9fa';
    });
  });
  
  // Enhancement type toggle buttons
  const typeToggleBtns = panel.querySelectorAll('.type-toggle-btn');
  
  // Track which types are active (all start as active)
  const activeTypes = new Set(['bulk shell', 'seeded cultch', 'singles']);
  
  // Function to normalize enhancement type strings
  function normalizeType(typeString) {
    if (!typeString) return [];
    // Split by comma, trim whitespace, convert to lowercase
    return typeString.split(',')
      .map(t => t.trim().toLowerCase())
      .filter(t => t.length > 0);
  }
  
  // Function to filter enhancement markers by type
  function filterEnhancementMarkers() {
    // Loop through enhancement data and show/hide markers
    enhData.forEach(site => {
      const marker = window.markersBySite[site.site_name];
      if (marker) {
        // Normalize the site's enhancement types (handles comma-separated lists)
        const siteTypes = normalizeType(site.enhancement_actions);
        
        // Check if any of the site's types are active
        const shouldShow = siteTypes.some(type => activeTypes.has(type));
        
        // Show or hide marker
        if (shouldShow) {
          if (!enhancementLayer.hasLayer(marker)) {
            enhancementLayer.addLayer(marker);
          }
        } else {
          if (enhancementLayer.hasLayer(marker)) {
            enhancementLayer.removeLayer(marker);
          }
        }
      }
    });
  }
  
  // Add click handlers to toggle buttons
  typeToggleBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const type = btn.getAttribute('data-type');
      
      // Toggle the type in active set
      if (activeTypes.has(type)) {
        activeTypes.delete(type);
        // Style as inactive
        btn.style.background = 'white';
        btn.style.color = '#045B4C';
      } else {
        activeTypes.add(type);
        // Style as active
        btn.style.background = '#045B4C';
        btn.style.color = 'white';
      }
      
      // Filter markers
      filterEnhancementMarkers();
    });
    
    // Add hover effect
    btn.addEventListener('mouseenter', () => {
      if (!activeTypes.has(btn.getAttribute('data-type'))) {
        btn.style.background = '#e8f4f2';
        btn.style.color = '#045B4C';
      } else {
        btn.style.background = '#034a3e';
      }
    });
    
    btn.addEventListener('mouseleave', () => {
      if (!activeTypes.has(btn.getAttribute('data-type'))) {
        btn.style.background = 'white';
        btn.style.color = '#045B4C';
      } else {
        btn.style.background = '#045B4C';
        btn.style.color = 'white';
      }
    });
  });
  
  // Style the select dropdown on focus
  siteSelector.addEventListener('focus', () => {
    siteSelector.style.borderColor = '#045B4C';
    siteSelector.style.boxShadow = '0 0 0 3px rgba(4, 91, 76, 0.1)';
  });
  
  siteSelector.addEventListener('blur', () => {
    siteSelector.style.borderColor = '#e0e0e0';
    siteSelector.style.boxShadow = 'none';
  });
  
  return panel;
}
// ===================================================
// END FILTER PANEL COMPONENT
// ===================================================


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

  mainContainer._map = map;
  
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
      map.setView(
        [site.latitude, site.longitude],  // center the map at this coord
        13, // zoom level
        { animate: false } // jump instantly, no pan/zoom animation
      );
  })
    // Create back button to return to full map view
    const backButton = document.createElement("button");
    backButton.textContent = "← Back to Map";
    Object.assign(backButton.style, {
      marginBottom: "24px",
      padding: "10px 20px",
      cursor: "pointer",
      border: "2px solid #045B4C",
      borderRadius: "6px",
      backgroundColor: "white",
      color: "#045B4C",
      fontSize: "14px",
      fontWeight: "600",
      transition: "all 0.2s ease",
      textTransform: "uppercase",
      letterSpacing: "0.5px"
    });
    
    // Add hover effect to back button
    backButton.onmouseenter = () => {
      backButton.style.backgroundColor = "#045B4C";
      backButton.style.color = "white";
    };
    backButton.onmouseleave = () => {
      backButton.style.backgroundColor = "white";
      backButton.style.color = "#045B4C";
    };
    
    backButton.onclick = resetView;

    // Clear any previous story content
    detailContainer.innerHTML = "";
    detailContainer.appendChild(backButton);

    // Get tooltip photo if it exists, otherwise use empty array
    const photos = tooltipPhotos[site.site_name] ? [tooltipPhotos[site.site_name]] : [];

    // Define additional images for sites
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

    // Create section for site story info
    const content = document.createElement("div");

    // Build photo carousel if site has photos
    const carouselHTML = allPhotos.length > 0 ? `
      <div class="carousel" style="margin-bottom: 32px;">
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

    // Written site story content
    const siteStories = { 
      "Fidalgo Bay": {
        intro: "White clouds rise from grey smokestacks, blurring a sprawling refinery into the distant silhouette of Koma Kulshan. A retired railroad trestle cuts across the bay like an old scar. Human ambition is written plainly on the shoreline, and yet, millions of Olympia oysters tell a remarkable success story.",
        
        context: "The story of Fidalgo Bay begins with a rumor: that Olympia oysters, the Pacific Northwest’s only native oyster, once resided in these shallow waters. By the early 2000s, none remained, but the bay’s protected waters and limited predators made it an ideal candidate for restoration. In 2002, alongside a strong network of partners, we spread Pacific oyster shell covered in Olympia oyster seed beside the old trestle on the eastern shore, marking the first Olympia oyster restoration effort in northern Puget Sound.",
        
        ourWork: "What followed was a years-long conversation with the bay. Additional seeded cultch were added in subsequent years. Non-seed bearing Pacific oyster shells were introduced in 2006, 2008, and 2013 to enhance the substrate and expand the area available for larval settlement. When monitoring revealed that nearly all natural recruitment was concentrated on the eastern side, likely shaped by summer current patterns, we responded by seeding the west side of the bay in 2016. In 2018, two new half-acre plots of bulk Pacific shell were added, one on each side of the bay, and the west side was seeded once more months later to give larval abundance a fresh boost.",
        
        experience: "Since 2002, the estimated Olympia oyster population in Fidalgo Bay has grown from roughly 50,000 to over 5.5 million – a more than hundredfold increase over two decades. Growth through the 2000s and early 2010s was steady, from the initial 50,000 seeded individuals to 240,000 by 2013. Then, something shifted. The population began to accelerate, explosive growth driven no longer by our additions, but by the Olys themselves! The last 5 years alone saw numbers nearly double, from 2.9 million in 2018 to 5.5 million in 2023.",

        dataContext: "While most of these individuals remain within the enhanced shell plots, the Olys are expanding into areas where we wouldn’t have expected them. In 2023, we counted over 1.2 million oysters in the march channels at the far southern end of the bay, well beyond the reach of any direct seeding effort. This was not only the densest aggregation observed that year, but also home to some of the largest individual Olympia oysters recorded anywhere in Puget Sound, with some measuring over 70mm.",

        impact: "The story of Fidalgo Bay is, at its heart, a story showcasing the power of reiterative enhancement actions and strong community partnerships. Walk these tidelands today and you’ll find something quite extraordinary. (who can paint some imagery for us?). This would not have been possible without the extensive efforts of this incredible network or partners and community members.",

        future: "Fidalgo Bay is not oly a local success story, but also the starting point for Olympia oyster restoration across the region. Adult oysters from here have been raised as hatchery broodstock, transplanted directly to new sites, and (in a particularly elegant turn) the bay itself has functioned as a natural hatchery, with post-larvae captured on Pacific oyster cultch bags and transferred to other bays. Restoration efforts in Sequim Bay, Fisherman Bay on Lopez Island, Skagit and Similk Bays, Padilla Bay, Samish Bay, Chuckanut Bay, and Drayton Harbor have all been seeded by what grew here. Since 2002, approximately 3,000 bags of spat-on-shell from Fidalgo Bay broodstock have gone out to support restoration across the north Sound.",
        funders: [
              "NOAA",
              "Rose Foundation for Communities and the Environment",
              "Funders"
          ],

        partners: [
              "Skagit MRC",
              "Samish Indian Nation",
              "Swinomish Indian Tribal Community",
              "Taylor Shellfish Farms",
              "Shell Puget Sound Refinery",
              "City of Anacortes"
          ]
      }
    };

    // Get story for this site, or use this default (change later!! if there is no site story, just show plots, or make the site not clickable)
    const story = siteStories[site.site_name] || {
      intro: `A warm, image-provoking sentence about what this site is / represents / feels like.`,
      context: "Some history of the site, including oly historic populations if possible. Good place to mention people and communities that value this land.",
      ourWork: `Written description of our work, adding more "facts" and "info" while keeping things engaging.`,
      experience: "What's it like now? What would you experience if you visited?",
      dataContext: "A highlighted sentence from the section above that puts this data into context.",
      impact: "Some interpretation of what this data means. More context to lead into another plot (shell height distribtuions)",
      future: "What's next? Is our work here complete, passing the torch to the Oly's who can take it from here? Plans for more enhancements?",
      funders: [
            "List",
            "of",
            "Funders"
         ],

        partners: [
            "List",
            "of",
            "Partners"
         ] 
    };

    // Build the narrative content with data interwoven
    content.innerHTML = `

      <!-- Header with Timeline -->
        <div style="
        background: white;
        padding: 24px 32px;
        border-radius: 8px;
        margin-bottom: 32px;
        border: 2px solid #045B4C;
        ">
        <h2 style="
            margin: 0 0 30px 0;
            font-size: 32px;
            font-weight: 700;
            letter-spacing: 0.5px;
            line-height: 1.2;
            text-align: center;
            color: #045B4C;
        ">${site.site_name}</h2>
       <!-- <div id="timeline-plot-container"></div> -->
        </div>

      ${carouselHTML}

      <!-- Opening narrative -->
      <div style="
        font-size: 16px;
        line-height: 1.8;
        color: #333;
        margin-bottom: 32px;
        padding: 24px;
        background: linear-gradient(to right, #f0f7f6, transparent);
        border-left: 4px solid #045B4C;
        font-style: italic;
      ">
        ${story.intro}
      </div>

      <!-- Context section -->
      <div style="margin-bottom: 40px;">
        <h3 style="
          font-size: 18px;
          font-weight: 700;
          color: #045B4C;
          margin: 0 0 16px 0;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        ">About This Site</h3>
        <p style="
          font-size: 15px;
          line-height: 1.8;
          color: #444;
          margin: 0;
        ">${story.context}</p>
      </div>

      <!-- Our work section -->
      <div style="
        background: #f8f9fa;
        padding: 24px;
        border-radius: 8px;
        margin-bottom: 40px;
      ">
        <h3 style="
          font-size: 18px;
          font-weight: 700;
          color: #045B4C;
          margin: 0 0 16px 0;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        ">Our Work</h3>
        <p style="
          font-size: 15px;
          line-height: 1.8;
          color: #444;
          margin: 0;
        ">${story.ourWork}</p>
      </div>

      <!-- Experience section -->
      <div style="margin-bottom: 40px;">
        <p style="
          font-size: 15px;
          line-height: 1.8;
          color: #444;
          margin: 0;
        ">${story.experience}</p>
      </div>

      <!-- Data transition -->
      <div style="
        padding: 20px;
        background: linear-gradient(135deg, #e8f4f2 0%, #f0f7f6 100%);
        border-radius: 8px;
        border-left: 4px solid #045B4C;
        margin-bottom: 24px;
      ">
        <p style="
          font-size: 15px;
          line-height: 1.7;
          color: #333;
          margin: 0;
          font-weight: 500;
        ">${story.dataContext}</p>
      </div>

      <!-- FIRST PLOT: Population Density Over Time -->
      <div style="
        background: white;
        padding: 24px;
        border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        margin-bottom: 40px;
      ">
        <h3 style="
          font-size: 16px;
          font-weight: 700;
          color: #045B4C;
          margin: 0 0 8px 0;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        ">Population Density Over Time</h3>
        <p style="
          font-size: 13px;
          color: #666;
          margin: 0 0 20px 0;
          font-style: italic;
        ">Tracking oyster abundance from initial restoration through today</p>
        <div id="density-plot-container"></div>
      </div>

      <!-- Continue narrative after plot -->
      <div style="margin-bottom: 40px;">
        <p style="
          font-size: 15px;
          line-height: 1.8;
          color: #444;
          margin: 0;
        ">${story.impact}</p>
      </div>

      <!-- Placeholder for future plots -->
      <div style="
        background: white;
        padding: 24px;
        border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        margin-bottom: 40px;
      ">
        <h3 style="
          font-size: 16px;
          font-weight: 700;
          color: #045B4C;
          margin: 0 0 8px 0;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        ">Placeholder for shell height plot</h3>
      </div>

      <!-- Looking forward -->
      <div style="
        background: linear-gradient(135deg, #f0f7f6 0%, #e8f4f2 100%);
        padding: 28px;
        border-radius: 8px;
        border-left: 4px solid #045B4C;
        margin-bottom: 20px;
      ">
        <h3 style="
          font-size: 18px;
          font-weight: 700;
          color: #045B4C;
          margin: 0 0 16px 0;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        ">Looking Ahead</h3>
        <p style="
          font-size: 15px;
          line-height: 1.8;
          color: #444;
          margin: 0;
        ">${story.future}</p>
      </div>

      <!-- Funders & Partners: Two Column Layout -->
<div style="
  margin-bottom: 40px;
  background: #f8f9fa;
  padding: 32px;
  border-radius: 8px;
">
  <div style="
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 32px;
  ">

    <!-- Funders Column -->
    <div>
      <h3 style="
        font-size: 16px;
        font-weight: 700;
        color: #045B4C;
        margin: 0 0 16px 0;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        border-bottom: 2px solid #045B4C;
        padding-bottom: 8px;
      ">Funders</h3>

      <ul style="
        list-style: none;
        padding: 0;
        margin: 0;
      ">
        ${story.funders.map(funder => `
          <li style="
            padding: 10px 12px;
            margin-bottom: 8px;
            background: white;
            border-radius: 6px;
            border-left: 4px solid #045B4C;
            font-size: 14px;
            color: #333;
          ">
            ${funder}
          </li>
        `).join('')}
      </ul>
    </div>

    <!-- Partners Column -->
    <div>
      <h3 style="
        font-size: 16px;
        font-weight: 700;
        color: #045B4C;
        margin: 0 0 16px 0;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        border-bottom: 2px solid #045B4C;
        padding-bottom: 8px;
      ">Partners</h3>

      <ul style="
        list-style: none;
        padding: 0;
        margin: 0;
      ">
        ${story.partners.map(partner => `
          <li style="
            padding: 10px 12px;
            margin-bottom: 8px;
            background: white;
            border-radius: 6px;
            border-left: 4px solid #056657;
            font-size: 14px;
            color: #333;
          ">
            ${partner}
          </li>
        `).join('')}
      </ul>
    </div>

  </div>
</div>
    `;

    
    
    detailContainer.appendChild(content);

    // ===================================================
    // Create and Insert Timeline Plot
    // ===================================================
    const timelineContainer = content.querySelector('#timeline-plot-container');
    if (timelineContainer) {
    timelineContainer.appendChild(
        createEnhancementTimeline(window.timelineData, site.site_name)
    );
    } 
  
    // ===================================================
    // Carousel Functionality
    // ===================================================
    if (allPhotos.length > 0) {
      const images = content.querySelectorAll('.carousel-image');
      const dotsContainer = content.querySelector('.carousel-dots');
      let currentIndex = 0;
    
      images.forEach((_, index) => {
        const dot = document.createElement('span');
        dot.className = 'carousel-dot' + (index === 0 ? ' active' : '');
        dot.onclick = () => showImage(index);
        dotsContainer.appendChild(dot);
      });
    
      const dots = content.querySelectorAll('.carousel-dot');
    
      function showImage(index) {
        images[currentIndex].classList.remove('active');
        dots[currentIndex].classList.remove('active');
        currentIndex = index;
        images[currentIndex].classList.add('active');
        dots[currentIndex].classList.add('active');
      }
      
      content.querySelector('.prev').onclick = () => {
        showImage((currentIndex - 1 + images.length) % images.length);
      };
      
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

    // Skip if coordinates are missing
    if (!site.latitude || !site.longitude ||
        site.latitude === 'NA' || site.longitude === 'NA' ||
        isNaN(parseFloat(site.latitude)) || isNaN(parseFloat(site.longitude))) {
      return;
    }

    // Create marker at site coordinates with CIRCLE icon
    const marker = L.marker(
      [site.latitude, site.longitude],
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
        Type: ${site.enhancement_actions}<br>
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
    .addTo(enhancementLayer);  // Add to enhancement layer
  
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
        <div style="display: flex; align-items: center; margin: 5px 0;">
          <div style="
            background-color: #4e79a7;
            width: 14px;
            height: 14px;
            border-radius: 50%;
            border: 2px solid white;
            margin-right: 8px;
          "></div>
          Enhancement Project
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
          Recruitment Monitoring Station
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
// TIMELINE PLOT FUNCTION FOR STORY PANEL
// This creates a timeline showing enhancement work at each site
// ===================================================
function createEnhancementTimeline(data, selectedSite) {

    // Filter data to the selected site
    const siteData = data.filter(d => d.site_name === selectedSite);

    // Return an empty div if there is no data
    if (siteData.length === 0) {
        return document.createElement('div');
    }

    // Calculate number of lines and assign variable tick heights
    const preparedData = siteData.map((d, i) => {
        const text = d.timeline_text || '';
        const numberOfLines = Math.ceil(text.length / 30);
        // Variable tick heights to create vertical separation
        const tickPattern = [50, 80, 110];
        const tickHeight = tickPattern[i % 3];
        
        return {
        ...d,
        numberOfLines: Math.max(numberOfLines, 1),
        tickHeight: tickHeight
        };
    });

    // Calculate height dynamically
    const maxLines = Math.max(...preparedData.map(d => d.numberOfLines));
    const maxTick = Math.max(...preparedData.map(d => d.tickHeight));
    const height = Math.max(300, maxLines * 16 + maxTick * 2 + 20);

    return Plot.plot({
        style: {
            fontSize: "14px",
            fontFamily: "inherit"
        },
        height,
        marginLeft: 50,
        marginRight: 50,
        marginTop: 10,
        marginBottom: 10,
        x: {axis: null},
        y: { axis: null, domain: [-height / 2, height / 2] },
        marks: [
            // Horizontal timeline line
            Plot.ruleY([0], { stroke: "#045B4C", strokeWidth: 2 }),
            
            // Vertical tick marks with variable lengths
            Plot.ruleX(preparedData, {
                x: "year",
                y1: 0,
                y2: (d, i) => (i % 2 === 0 ? d.tickHeight : -d.tickHeight),
                stroke: "#045B4C",
                strokeWidth: 2.5
            }),
            // Dots at each year
            Plot.dot(preparedData, { 
                x: "year", 
                fill: "#fff", 
                stroke: "#045B4C",
                strokeWidth: 2,
                r: 5
            }),
            
            // Year labels (alternate above/below opposite to text)
            Plot.text(preparedData, {
                x: "year",
                y: (d, i) => (i % 2 === 0 ? -18 : 18),
                text: (d) => d.year.toString(),
                fill: "#045B4C",
                fontWeight: "bold",
                fontSize: 14
            }),
            
            // Timeline text descriptions
            Plot.text(preparedData, {
                x: "year",
                y: (d, i) =>
                i % 2 === 0
                    ? d.tickHeight + d.numberOfLines * 13 + 5
                    : -d.tickHeight - d.numberOfLines * 13 - 5,
                text: "timeline_text",
                fill: "#333",
                lineWidth: 12,
                fontSize: 12,
                textAnchor: "middle"
            })
        ]
    })
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
  const container = oysterMap(enh_sites_metadata, recruit_sites, ann_densities, {width});
  // Store reference globally so filter panel can access it
  window.currentMapInstance = container;
  
  // Reconnect filter panel to new map instance after resize
  setTimeout(() => {
    const filterContainer = document.querySelector('#filter-container');
    if (filterContainer && container._enhancementLayer) {
      // Clear existing filter panel
      filterContainer.innerHTML = '';
      // Create new filter panel connected to current map
      filterContainer.appendChild(
        createFilterPanel(
          container._enhancementLayer,
          container._recruitmentLayer,
          container._map,
          enh_sites_metadata
        )
      );
    }
  }, 100);
  
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


<!-- Filter and Map card displays -->
<div class="grid grid-cols-4">
  <div class="card">
    ${(function() {
  // Wait for map to load, then create filter panel
  setTimeout(() => {
    const container = document.querySelector('#filter-container');
    if (window.currentMapInstance && container) {
      container.innerHTML = '';  // clear before appending
      container.appendChild(
        createFilterPanel(
          window.currentMapInstance._enhancementLayer,
          window.currentMapInstance._recruitmentLayer,
          window.currentMapInstance._map,
          enh_sites_metadata  // Pass the enhancement data for the dropdown
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

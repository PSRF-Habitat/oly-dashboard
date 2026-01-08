---
toc: false
title: "Side-by-side maps and plots with interactivity"
theme: dashboard
---

# A SUPER AWESOME TITLE!!

And maybe even some text for folks that like to read!

<!-- ===================================================== -->
<!-- Page grid layout -->
<!-- ===================================================== -->
<div class="grid grid-cols-2">
  
  <!-- Map card -->
  <div class="card grid-rowspan-2">
  ${resize((width) => oysterMap(enh_sites, recruit_sites, {width}))}
  </div>
  
  <!-- Top right card --> 
  <div class="card">

 **Olympia Oyster Densities Throughout Puget Sound**
  ${resize((width) => densityPlot(ann_densities, {width}))}
  </div>
  
  <!-- Bottom right card --> 
  <div class="card">

**Olympia Oyster Recruitment Index**
 ${resize((width) => recruitPlot(recruit_index, {width}))}

  </div>
  
</div>

<!-- ===================================================== -->
<!-- INTERACTIVE LEAFLET MAP -->
<!-- This section creates the map with enhancement and recruitment sites -->
<!-- ===================================================== -->

```js
// Load the enhancement sites CSV 
const enh_sites = await FileAttachment("data/enhancements.csv").csv({typed: true});

// Load the recruitment sites CSV
const recruit_sites = await FileAttachment("data/recruitment_station_info.csv").csv({typed: true});

// Import required libraries
import * as L from "npm:leaflet@1.9.4";  // Leaflet for map
import * as d3 from "npm:d3";            // D3 for plot

// ===================================================
// GLOBAL STATE MANAGEMENT
// These variables track the current state across map and plot
// ===================================================

// Track which location is currently being hovered over
window.highlightedLocation = null;

// Track which site is currently selected/clicked (so it can stay highlighted)
window.selectedSite = null;

// ===================================================
// MAP CONFIGURATION
// ===================================================

// Center point for map loading (Puget Sound area)
const center = [47.8, -123.5];

// Initial zoom level
const zoom = 8;

// List of sites that have story pages - only these sites will be clickable for more info
const sitesWithDetails = ["Port Gamble Bay", "Quilcene Bay"];

// Define tooltip photos for each site
const sitePhotos = {
  "Port Gamble Bay": FileAttachment("data/images/port_gamble_SAMPLE_tooltip.jpg").href,
  "Quilcene Bay": FileAttachment("data/images/quilcene_SAMPLE_tooltip.jpg").href,
  "Sinclair Inlet": FileAttachment("data/images/sinclair_SAMPLE_tooltip.jpg").href,
  "Legion Park": FileAttachment("data/images/legion_SAMPLE_tooltip.jpg").href
};

// ===================================================
// CREATE CUSTOM MARKER ICONS
// Different shapes for different data types
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
// MAIN MAP FUNCTION
// This creates the entire map, including story/detail panels
// Now handles TWO datasets: enhancement and recruitment
// ===================================================
function oysterMap(enhData, recruitData, {width} = {}) {
  // Create the main container that holds both map and story panel
  const mainContainer = document.createElement("div");
  Object.assign(mainContainer.style, {
    width: `${width}px`,
    height: "900px",
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
  // CREATE LAYER GROUPS
  // Separate layers to toggle different data types on/off
  // ===================================================
  const enhancementLayer = L.layerGroup().addTo(map);
  const recruitmentLayer = L.layerGroup().addTo(map);
  
  // Global object to store marker references by site name
  // This allows us to access markers from other functions (like the plot)
  window.markersBySite = {};

  // ===================================================
  // SHOW DETAIL PANEL FUNCTION
  // Called when user clicks on a marker with details
  // ===================================================
  function showDetail(site) {
    // Set this site as the selected site
    window.selectedSite = site.site_name;
    
    // Update plot to show this site's line highlighted
    if (window.updatePlotHighlight) {
      window.updatePlotHighlight(site.site_name);
    }

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

    // Clean any previous story content
    detailContainer.innerHTML = "";
    detailContainer.appendChild(backButton);

    // Define which images to show for each site
    // UPDATE as more are added!!! SAMPLE IMAGES FOR NOW!!!
    const siteImages = {
  "Port Gamble Bay": [
    sitePhotos["Port Gamble Bay"],  // Use the same tooltip photo as first image
    FileAttachment("data/images/oly_sample_pic.jpg").href,
    FileAttachment("data/images/beach_sample_pic.jpg").href
  ].filter(Boolean),  // Remove undefined values if no tooltip photo exists
  
  "Quilcene Bay": [
    sitePhotos["Quilcene Bay"]
  ].filter(Boolean)
};
    
    // Get images for selected site (or empty array if none)
    const photos = siteImages[site.site_name] || [];

    // Create section ("div") for site story info
    const content = document.createElement("div");

    // Build photo carousel if site has photos
    const carouselHTML = photos.length > 0 ? `
      <div class="carousel">
        <button class="carousel-btn prev">‹</button>
        <div class="carousel-images">
          ${photos.map((url, i) => 
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
    `;
    
    detailContainer.appendChild(content);
  
    // ===================================================
    // CAROUSEL FUNCTIONALITY
    // Only set up if there are photos to display
    // ===================================================
    if (photos.length > 0) {
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
  }

  // ===================================================
  // RESET VIEW FUNCTION
  // Returns to full map view, closing detail panel
  // ===================================================
  function resetView() {
    // Clear the selected site
    window.selectedSite = null;

    // Update plot to remove persistent highlighting when going back
    if (window.updatePlotHighlight) {
      window.updatePlotHighlight(null);
    }

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

        // Reset all marker tooltips to non-permanent
        map.eachLayer((layer) => {
          if (layer instanceof L.Marker && layer.getTooltip()) {
            const tooltipContent = layer.getTooltip().getContent();
            layer.unbindTooltip();
            layer.bindTooltip(tooltipContent, {
              direction: 'top',
              permanent: false  // Tooltip only shows on hover
            });
          }
        });

        // Make sure plot tooltip is reset
        if (window.plotTooltip) {
          window.plotTooltip.style("display", "none");
        }
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
    console.log("Skipping site with invalid coordinates:", site.site_name);
    return;
  }
  
  // Create marker at site coordinates with TRIANGLE icon
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
  
  // ===================================================
  // MARKER HOVER INTERACTIONS FOR RECRUITMENT PLOT
  // When mouse hovers over marker, highlight corresponding line in recruitment plot
  // ===================================================
  marker.on('mouseover', () => {
  window.highlightedLocation = site.standard_station;
  // Connect to recruitment plot instead of density plot
  if (window.updateRecruitmentPlotHighlight) {
    window.updateRecruitmentPlotHighlight(site.standard_station);
  }
});

marker.on('mouseout', () => {
  window.highlightedLocation = null;
  if (window.updateRecruitmentPlotHighlight) {
    window.updateRecruitmentPlotHighlight(null);
  }
});
});
  
  // ===================================================
  // ADD ENHANCEMENT MARKERS
  // Loop through all enhancement sites and add CIRCLE markers
  // ===================================================
  enhData.forEach(site => {
    // Check if this site has a detail page available
    const hasDetails = sitesWithDetails.includes(site.site_name);

    // Create marker at site coordinates with CIRCLE icon
    const marker = L.marker(
      [site.enhancement_latitude_est, site.enhancement_longitude_est],
      { icon: enhancementIcon }  // Blue circle
    )
    .bindTooltip(() => {
  const photoUrl = sitePhotos[site.site_name];
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
        ${site.site_name}${hasDetails ? ' 📖' : ''}
      </div>
      ${photoHTML}
      <div style="font-size: 12px; margin-top: 4px;">
        Type: ${site.enhancement_type}<br>
        Years: ${site.enhancement_years}
        ${hasDetails ? '<br><em style="color: #007bff; font-size: 11px;">▶ Click for more details</em>' : ''}
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

    // ===================================================
    // MARKER HOVER INTERACTIONS
    // When mouse hovers over marker, highlight corresponding line in plot
    // ===================================================
    marker.on('mouseover', () => {
      window.highlightedLocation = site.site_name;
      if (window.updatePlotHighlight) window.updatePlotHighlight(site.site_name);
    });
    
    marker.on('mouseout', () => {
      window.highlightedLocation = null;
      if (window.updatePlotHighlight) window.updatePlotHighlight(null);
    });

    // ===================================================
    // MARKER CLICK INTERACTION
    // Only sites with details show panel
    // ===================================================
    marker.on('click', () => {
      if (hasDetails) {
        showDetail(site);
      }
    });
  });

  
  // ===================================================
  // ADD LAYER CONTROL
  // This creates the checkbox interface to toggle layers on/off
  // ===================================================
  const overlays = {
    "Enhancement Sites": enhancementLayer,
    "Recruitment Sites": recruitmentLayer
  };
  
  L.control.layers(null, overlays, {
    collapsed: false,  // Keep it expanded so users see it
    position: 'topright'
  }).addTo(map);

  // ===================================================
  // ADD LEGEND
  // Shows what each marker shape/color means
  // ===================================================
  const legend = L.control({position: 'bottomleft'});

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

  // Small delay to allow data to load before rendering map
  setTimeout(() => map.invalidateSize(), 100);
  
  return mainContainer;
}
```
<!-- Link to Leaflet CSS (required for proper map styling, I suppose) -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/leaflet@1.9.4/dist/leaflet.css" /> 

<!-- ===================================================== -->
<!-- CUSTOM STYLES FOR MAP AND CAROUSEL -->
<!-- ===================================================== -->
<style>  
  /* Override Leaflet default font to match page */
  .leaflet-container { font-family: inherit; }

  /* Style the map attribution (copyright text in corner) */
  .leaflet-control-attribution {
    background-color: rgba(255, 255, 255, 0.7);
    font-size: 10px; 
    opacity: 0.6;
    padding: 2px 5px;
  }
  .leaflet-control-attribution:hover { opacity: 1; }
  
  /* ============================= */
  /* PHOTO CAROUSEL STYLES */
  /* ============================= */

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
    padding-bottom: 66%; /* 16:9 aspect ratio - adjust as needed */
  }
  .carousel-image {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: contain;  /* Scale image to fit without cropping */
    opacity: 0;  /* Hide images by default */
    transition: opacity 0.3s ease;
    pointer-events: none;
    background: #f5f5f5; /* Add background so letterboxing looks clean */
  }
   /* Active image is visible */
  .carousel-image.active {
    opacity: 1;
    pointer-events: auto;
  }
   /* Previous/Next navigation buttons */
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
  /* Individual dot styling */
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

/* Ensure images load smoothly */
.custom-tooltip img {
  display: block;
  background: #f0f0f0;
}
</style>

<!-- ===================================================== -->
<!-- OYSTER DENSITY PLOT WITH D3 USED FOR BEST INTERACTIVITY-->
<!-- ===================================================== -->

```js
// Load oyster population assessment CSV
const ann_densities = await FileAttachment("data/assessments.csv").csv({typed: true});

// ===================================================
// MAIN DENSITY PLOT FUNCTION
// Creates an interactive line chart
// ===================================================
function densityPlot(data, {width} = {}) {
 
  // ===================================================
  // CHART DIMENSIONS AND MARGINS
  // ===================================================
  const height = 400;
  const marginTop = 30;
  const marginRight = 50;
  const marginBottom = 40;
  const marginLeft = 50;

  // ===================================================
  // DATA PREP
  // Grab unique locations and years
  // ===================================================
  const locations = Array.from(new Set(data.map(d => d.location)));
  const years = Array.from(new Set(data.map(d => d.year))).sort((a, b) => a - b);
  
  // ===================================================
  // COLOR SCALE
  // Observable's default color scheme (Tableau10)
  // ===================================================
  const color = d3.scaleOrdinal(d3.schemeTableau10).domain(locations);

  // ===================================================
  // AXIS SCALES
  // X-axis: Years (time)
  // Y-axis: Density (counts per square meter)
  // ===================================================
  const x = d3.scaleLinear()
    .domain(d3.extent(years))  // From min to max year
    .range([marginLeft, width - marginRight]);

  const y = d3.scaleLinear()
    .domain([0, d3.max(data, d => d.density)])  // From 0 to max density
    .nice()  // Round to nice numbers
    .range([height - marginBottom, marginTop]);

  // ===================================================
  // CREATE SVG OBJECT FOR DRAWING PLOT
  // ===================================================
  const svg = d3.create("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("viewBox", [0, 0, width, height])
    .attr("style", "max-width: 100%; height: auto;");

  // ===================================================
  // ADD AXES
  // Styled to match Observable Plot
  // ===================================================
  
  /// X-axis
svg.append("g")
  .attr("transform", `translate(0,${height - marginBottom})`)
  .call(d3.axisBottom(x)
    .tickFormat(d3.format("d"))
    .ticks(5))
  .call(g => g.select(".domain").remove()) // Remove axis line like Plot
  .call(g => g.selectAll(".tick line")
    .attr("stroke", "#e5e5e5")
    .attr("stroke-width", 1))
  .call(g => g.selectAll(".tick text")
    .attr("fill", "#6b7280")
    .attr("font-size", "11px"));

// Y-axis  
svg.append("g")
  .attr("transform", `translate(${marginLeft},0)`)
  .call(d3.axisLeft(y).ticks(5))
  .call(g => g.select(".domain").remove()) // Remove axis line
  .call(g => g.selectAll(".tick line")
    .attr("stroke", "#e5e5e5")
    .attr("stroke-width", 1))
  .call(g => g.selectAll(".tick text")
    .attr("fill", "#6b7280")
    .attr("font-size", "11px"));

// Update gridlines
svg.append("g")
  .attr("class", "grid")
  .attr("transform", `translate(${marginLeft},0)`)
  .call(d3.axisLeft(y)
    .ticks(5)
    .tickSize(-(width - marginLeft - marginRight))
    .tickFormat(""))
  .call(g => g.select(".domain").remove())
  .call(g => g.selectAll(".tick line")
    .attr("stroke", "#e5e5e5")
    .attr("stroke-opacity", 1)); // More visible gridlines

  // ===================================================
  // ADD GRIDLINES (subtle, like Observable Plot)
  // ===================================================
  
  // Horizontal gridlines (for Y-axis)
  svg.append("g")
    .attr("class", "grid")
    .attr("transform", `translate(${marginLeft},0)`)
    .call(d3.axisLeft(y)
      .ticks(5)
      .tickSize(-(width - marginLeft - marginRight))  // Extend across chart
      .tickFormat(""))  // No labels on gridlines
    .call(g => g.select(".domain").remove())  // Remove axis line
    .call(g => g.selectAll(".tick line")
      .attr("stroke", "#f0f0f0")  // Very light gray
      .attr("stroke-opacity", 0.7));

  // ===================================================
  // AXIS LABELS
  // Positioned like Observable Plot defaults
  // ===================================================
  
  // X-axis label
  svg.append("text")
    .attr("x", width / 2)
    .attr("y", height - 5)
    .attr("text-anchor", "middle")
    .attr("font-size", 12)
    .attr("fill", "#666")
    .text("Year");

  // Y-axis label (rotated)
  svg.append("text")
    .attr("x", -height / 2)
    .attr("y", 15)
    .attr("text-anchor", "middle")
    .attr("transform", "rotate(-90)")
    .attr("font-size", 12)
    .attr("fill", "#666")
    .text("Density (m⁻²)");

  // ===================================================
  // LINE GENERATOR
  // Converts data points into SVG path
  // ===================================================
  const line = d3.line()
    .x(d => x(d.year))
    .y(d => y(d.density));

  // ===================================================
  // GROUP DATA BY LOCATION
  // Each location has its own line
  // ===================================================
  const dataByLocation = d3.group(data, d => d.location);

  // ===================================================
  // DRAW BACKGROUND LINES (gray, always visible)
  // These show all the data in a neutral color
  // ===================================================
   dataByLocation.forEach((values, location) => {
    svg.append("path")
      .datum(values.sort((a, b) => a.year - b.year))  // Sort by year
      .attr("class", `line-grey line-${location.replace(/\s+/g, '-')}`)
      .attr("fill", "none")
      .attr("stroke", "#ddd")  // Light gray
      .attr("stroke-width", 2)
      .attr("d", line);
  });

  // ===================================================
  // DRAW BACKGROUND DOTS (gray, always visible)
  // Show each individual data point
  // ===================================================
  svg.append("g")
    .selectAll("circle")
    .data(data)
    .join("circle")
    .attr("class", d => `dot-grey dot-${d.location.replace(/\s+/g, '-')}`)
    .attr("cx", d => x(d.year))
    .attr("cy", d => y(d.density))
    .attr("r", 4)
    .attr("fill", "#ddd")
    .attr("stroke", "white")
    .attr("stroke-width", 1.5);

  // ===================================================
  // DRAW COLORED LINES (hidden by default, shown on hover/select)
  // These appear on top when a location is highlighted
  // ===================================================
  dataByLocation.forEach((values, location) => {
    svg.append("path")
      .datum(values.sort((a, b) => a.year - b.year))
      .attr("class", `line-color line-${location.replace(/\s+/g, '-')}`)
      .attr("fill", "none")
      .attr("stroke", color(location))  // Use color scale
      .attr("stroke-width", 2.5)
      .attr("opacity", 0)  // Hidden initially
      .attr("d", line);
  });

  // ===================================================
  // DRAW COLORED DOTS (hidden by default)
  // Colored dots that appear when location is highlighted
  // ===================================================
  svg.append("g")
    .selectAll("circle")
    .data(data)
    .join("circle")
    .attr("class", d => `dot-color dot-${d.location.replace(/\s+/g, '-')}`)
    .attr("cx", d => x(d.year))
    .attr("cy", d => y(d.density))
    .attr("r", 5)
    .attr("fill", d => color(d.location))
    .attr("stroke", "white")
    .attr("stroke-width", 2)
    .attr("opacity", 0)  // Hidden initially
    .style("pointer-events", "none");  // Don't interfere with hover areas

  // ===================================================
  // CREATE TOOLTIP
  // Shows location, year, and density on hover
  // ===================================================
  const tooltip = svg.append("g")
    .attr("class", "tooltip")
    .style("display", "none");  // Hidden by default

  // Save reference globally
  window.plotTooltip = tooltip;

  // White background box for tooltip
  tooltip.append("rect")
    .attr("fill", "white")
    .attr("stroke", "#999")
    .attr("stroke-width", 1)
    .attr("rx", 4)  // Rounded corners
    .attr("filter", "drop-shadow(0 2px 4px rgba(0,0,0,0.1))");  // Subtle shadow

  // Text inside tooltip
  tooltip.append("text")
    .attr("class", "tooltip-text")
    .attr("x", 8)
    .attr("y", 18)
    .attr("font-size", 13)
    .attr("fill", "#333");

  // ===================================================
  // CREATE LARGE INVISIBLE HOVER AREAS
  // Much easier to interact with than tiny dots!
  // Creates a Voronoi diagram to divide chart into hover regions
  // ===================================================
  
  // Voronoi divides the chart into polygons, each closest to one data point
  const voronoi = d3.Delaunay
    .from(data, d => x(d.year), d => y(d.density))
    .voronoi([marginLeft, marginTop, width - marginRight, height - marginBottom]);

  // Add invisible polygons for each data point (large hover target)
  svg.append("g")
    .attr("class", "voronoi")
    .selectAll("path")
    .data(data)
    .join("path")
    .attr("d", (d, i) => voronoi.renderCell(i))  // Draw polygon for each point
    .attr("fill", "none")  // Invisible
    .attr("pointer-events", "all")  // But still captures mouse events
    .attr("cursor", "pointer")
    .on("mouseover", function(event, d) {
        
        const location = d.location;
        window.highlightedLocation = location;
        updateHighlight(location);
        
        // Update map markers (fade out non-hovered markers)
        if (window.markersBySite && window.markersBySite[location]) {
          Object.entries(window.markersBySite).forEach(([name, marker]) => {
            const el = marker.getElement();
            if (el) {
              el.style.opacity = name === location ? '1' : '0.3';
            }
            // Open tooltip for hovered location
         if (name === location) {
              marker.openTooltip();
             } else {
               marker.closeTooltip();
             }
          });
        }

        // Show and position tooltip
        tooltip.style("display", null);
        tooltip.select(".tooltip-text")
          .text(`${location}, ${d.year}: ${d.density.toFixed(2)} m⁻²`);
        
        // Size tooltip background to fit text
        const bbox = tooltip.select("text").node().getBBox();
        tooltip.select("rect")
          .attr("width", bbox.width + 16)
          .attr("height", bbox.height + 12)
          .attr("x", bbox.x - 8)
          .attr("y", bbox.y - 6);
        
        // Position tooltip near the data point
        tooltip.attr("transform", `translate(${x(d.year) - 85}, ${y(d.density) - 32})`);
      
    })
   .on("mouseout", function() {
  
  window.highlightedLocation = null;
  updateHighlight(null);
  tooltip.style("display", "none");
  
  // Reset all map markers and close tooltips
  if (window.markersBySite) {
    Object.values(window.markersBySite).forEach(marker => {
      const el = marker.getElement();
      if (el) el.style.opacity = '1';
      marker.closeTooltip(); // Add this line
    });
  }
})

  // ===================================================
  // HIGHLIGHT UPDATE FUNCTION
  // Shows/hides colored lines based on which location is active
  // ===================================================
function updateHighlight(location) {
  if (location) {
    const safeName = location.replace(/\s+/g, '-');

    // Hide all colored lines/dots
    svg.selectAll(`.line-color`).attr("opacity", 0);
    svg.selectAll(`.dot-color`).attr("opacity", 0);

    // Show the selected line and its dots
    svg.selectAll(`.line-color.line-${safeName}`).attr("opacity", 1);
    svg.selectAll(`.dot-color.dot-${safeName}`).attr("opacity", 1);
  } else {
    // No highlight - hide all colored lines/dots
    svg.selectAll(`.line-color`).attr("opacity", 0);
    svg.selectAll(`.dot-color`).attr("opacity", 0);
  }
}

  // ===================================================
  // MAKE UPDATE FUNCTION GLOBALLY ACCESSIBLE
  // This allows the map to call this function when markers are hovered
  // ===================================================
  window.updatePlotHighlight = updateHighlight;

  // ===================================================
  // CHECK IF A SITE IS ALREADY SELECTED
  // If user clicked a site before the plot loaded, highlight it now
  // ===================================================
  if (window.selectedSite) {
    updateHighlight(window.selectedSite);
  }

  return svg.node();
}
```

<!-- ===================================================== -->
<!-- RECRUITMENT INDEX PLOT WITH D3 USED FOR BEST INTERACTIVITY-->
<!-- ===================================================== -->

```js
// Load recruitment index CSV
const recruit_index = await FileAttachment("data/recruit_index.csv").csv({typed: true});

// ===================================================
// MAIN DENSITY PLOT FUNCTION
// Creates an interactive line chart
// ===================================================
function recruitPlot(data, {width} = {}) {
 
  // ===================================================
  // CHART DIMENSIONS AND MARGINS
  // ===================================================
  const height = 400;
  const marginTop = 30;
  const marginRight = 50;
  const marginBottom = 40;
  const marginLeft = 50;

  // ===================================================
  // DATA PREP
  // Grab unique locations and years
  // ===================================================
  // Filter out rows where index is NA, null, or not a number
const filteredData = data.filter(d => d.index !== null && d.index !== 'NA' && !isNaN(d.index));

const locations = Array.from(new Set(filteredData.map(d => d.standard_station_id)));
const years = Array.from(new Set(filteredData.map(d => d.year))).sort((a, b) => a - b);
  
  // ===================================================
  // COLOR SCALE
  // Observable's default color scheme (Tableau10)
  // ===================================================
  const color = d3.scaleOrdinal(d3.schemeTableau10).domain(locations);

  // ===================================================
  // AXIS SCALES
  // X-axis: Years (time)
  // Y-axis: Density (counts per square meter)
  // ===================================================
  const x = d3.scaleLinear()
    .domain(d3.extent(years))  // From min to max year
    .range([marginLeft, width - marginRight]);

  const y = d3.scaleLinear()
    .domain([0, d3.max(filteredData, d => d.index)])  // From 0 to max index
    .nice()  // Round to nice numbers
    .range([height - marginBottom, marginTop]);

  // ===================================================
  // CREATE SVG OBJECT FOR DRAWING PLOT
  // ===================================================
  const svg = d3.create("svg")
    .attr("width", width)
    .attr("height", height)
    .attr("viewBox", [0, 0, width, height])
    .attr("style", "max-width: 100%; height: auto;");

  // ===================================================
  // ADD AXES
  // Styled to match Observable Plot
  // ===================================================
  
  /// X-axis
svg.append("g")
  .attr("transform", `translate(0,${height - marginBottom})`)
  .call(d3.axisBottom(x)
    .tickFormat(d3.format("d"))
    .ticks(5))
  .call(g => g.select(".domain").remove()) // Remove axis line like Plot
  .call(g => g.selectAll(".tick line")
    .attr("stroke", "#e5e5e5")
    .attr("stroke-width", 1))
  .call(g => g.selectAll(".tick text")
    .attr("fill", "#6b7280")
    .attr("font-size", "11px"));

// Y-axis  
svg.append("g")
  .attr("transform", `translate(${marginLeft},0)`)
  .call(d3.axisLeft(y).ticks(5))
  .call(g => g.select(".domain").remove()) // Remove axis line
  .call(g => g.selectAll(".tick line")
    .attr("stroke", "#e5e5e5")
    .attr("stroke-width", 1))
  .call(g => g.selectAll(".tick text")
    .attr("fill", "#6b7280")
    .attr("font-size", "11px"));

// Update gridlines
svg.append("g")
  .attr("class", "grid")
  .attr("transform", `translate(${marginLeft},0)`)
  .call(d3.axisLeft(y)
    .ticks(5)
    .tickSize(-(width - marginLeft - marginRight))
    .tickFormat(""))
  .call(g => g.select(".domain").remove())
  .call(g => g.selectAll(".tick line")
    .attr("stroke", "#e5e5e5")
    .attr("stroke-opacity", 1)); // More visible gridlines

  // ===================================================
  // ADD GRIDLINES (subtle, like Observable Plot)
  // ===================================================
  
  // Horizontal gridlines (for Y-axis)
  svg.append("g")
    .attr("class", "grid")
    .attr("transform", `translate(${marginLeft},0)`)
    .call(d3.axisLeft(y)
      .ticks(5)
      .tickSize(-(width - marginLeft - marginRight))  // Extend across chart
      .tickFormat(""))  // No labels on gridlines
    .call(g => g.select(".domain").remove())  // Remove axis line
    .call(g => g.selectAll(".tick line")
      .attr("stroke", "#f0f0f0")  // Very light gray
      .attr("stroke-opacity", 0.7));

  // ===================================================
  // AXIS LABELS
  // Positioned like Observable Plot defaults
  // ===================================================
  
  // X-axis label
  svg.append("text")
    .attr("x", width / 2)
    .attr("y", height - 5)
    .attr("text-anchor", "middle")
    .attr("font-size", 12)
    .attr("fill", "#666")
    .text("Year");

  // Y-axis label (rotated)
  svg.append("text")
    .attr("x", -height / 2)
    .attr("y", 15)
    .attr("text-anchor", "middle")
    .attr("transform", "rotate(-90)")
    .attr("font-size", 12)
    .attr("fill", "#666")
    .text("Recruitment Index");

  // ===================================================
  // LINE GENERATOR
  // Converts data points into SVG path
  // ===================================================
  const line = d3.line()
    .x(d => x(d.year))
    .y(d => y(d.index));

  // ===================================================
  // GROUP DATA BY LOCATION
  // Each location has its own line
  // ===================================================
  const dataByLocation = d3.group(filteredData, d => d.standard_station_id);

  // ===================================================
  // DRAW BACKGROUND LINES (gray, always visible)
  // These show all the data in a neutral color
  // ===================================================
   dataByLocation.forEach((values, location) => {
    svg.append("path")
      .datum(values.sort((a, b) => a.year - b.year))  // Sort by year
      .attr("class", `line-grey line-${location.replace(/\s+/g, '-')}`)
      .attr("fill", "none")
      .attr("stroke", "#ddd")  // Light gray
      .attr("stroke-width", 2)
      .attr("d", line);
  });

  // ===================================================
  // DRAW BACKGROUND DOTS (gray, always visible)
  // Show each individual data point
  // ===================================================
  svg.append("g")
    .selectAll("circle")
    .data(filteredData)
    .join("circle")
    .attr("class", d => `dot-grey dot-${d.standard_station_id.replace(/\s+/g, '-')}`)
    .attr("cx", d => x(d.year))
    .attr("cy", d => y(d.index))
    .attr("r", 4)
    .attr("fill", "#ddd")
    .attr("stroke", "white")
    .attr("stroke-width", 1.5);

  // ===================================================
  // DRAW COLORED LINES (hidden by default, shown on hover/select)
  // These appear on top when a location is highlighted
  // ===================================================
  dataByLocation.forEach((values, location) => {
    svg.append("path")
      .datum(values.sort((a, b) => a.year - b.year))
      .attr("class", `line-color line-${location.replace(/\s+/g, '-')}`)
      .attr("fill", "none")
      .attr("stroke", color(location))  // Use color scale
      .attr("stroke-width", 2.5)
      .attr("opacity", 0)  // Hidden initially
      .attr("d", line);
  });

  // ===================================================
  // DRAW COLORED DOTS (hidden by default)
  // Colored dots that appear when location is highlighted
  // ===================================================
  svg.append("g")
    .selectAll("circle")
    .data(filteredData)
    .join("circle")
    .attr("class", d => `dot-color dot-${d.standard_station_id.replace(/\s+/g, '-')}`)
    .attr("cx", d => x(d.year))
    .attr("cy", d => y(d.index))
    .attr("r", 5)
    .attr("fill", d => color(d.standard_station_id))
    .attr("stroke", "white")
    .attr("stroke-width", 2)
    .attr("opacity", 0)  // Hidden initially
    .style("pointer-events", "none");  // Don't interfere with hover areas

  // ===================================================
  // CREATE TOOLTIP
  // Shows location, year, and index on hover
  // ===================================================
  const tooltip = svg.append("g")
    .attr("class", "tooltip")
    .style("display", "none");  // Hidden by default

  // Save reference globally
  window.plotTooltipIndex = tooltip;

  // White background box for tooltip
  tooltip.append("rect")
    .attr("fill", "white")
    .attr("stroke", "#999")
    .attr("stroke-width", 1)
    .attr("rx", 4)  // Rounded corners
    .attr("filter", "drop-shadow(0 2px 4px rgba(0,0,0,0.1))");  // Subtle shadow

  // Text inside tooltip
  tooltip.append("text")
    .attr("class", "tooltip-text")
    .attr("x", 8)
    .attr("y", 18)
    .attr("font-size", 13)
    .attr("fill", "#333");

  // ===================================================
  // CREATE LARGE INVISIBLE HOVER AREAS
  // Much easier to interact with than tiny dots!
  // Creates a Voronoi diagram to divide chart into hover regions
  // ===================================================
  
  // Voronoi divides the chart into polygons, each closest to one data point
  const voronoi = d3.Delaunay
    .from(filteredData, d => x(d.year), d => y(d.index))
    .voronoi([marginLeft, marginTop, width - marginRight, height - marginBottom]);

  // Add invisible polygons for each data point (large hover target)
  svg.append("g")
    .attr("class", "voronoi")
    .selectAll("path")
    .data(filteredData)
    .join("path")
    .attr("d", (d, i) => voronoi.renderCell(i))  // Draw polygon for each point
    .attr("fill", "none")  // Invisible
    .attr("pointer-events", "all")  // But still captures mouse events
    .attr("cursor", "pointer")
    .on("mouseover", function(event, d) {
        
        const location = d.standard_station_id;
        window.highlightedLocation = location;
        updateHighlight(location);
        
        // Update map markers (fade out non-hovered markers)
        if (window.markersBySite && window.markersBySite[location]) {
          Object.entries(window.markersBySite).forEach(([name, marker]) => {
            const el = marker.getElement();
            if (el) {
              el.style.opacity = name === location ? '1' : '0.3';
            }
            // Open tooltip for hovered location
         if (name === location) {
              marker.openTooltip();
             } else {
               marker.closeTooltip();
             }
          });
        }

        // Show and position tooltip
        tooltip.style("display", null);
        tooltip.select(".tooltip-text")
          .text(`${location}, ${d.year}: ${d.index.toFixed(2)} m⁻²`);
        
        // Size tooltip background to fit text
        const bbox = tooltip.select("text").node().getBBox();
        tooltip.select("rect")
          .attr("width", bbox.width + 16)
          .attr("height", bbox.height + 12)
          .attr("x", bbox.x - 8)
          .attr("y", bbox.y - 6);
        
        // Position tooltip near the data point
        tooltip.attr("transform", `translate(${x(d.year) - 85}, ${y(d.index) - 32})`);
      
    })
   .on("mouseout", function() {
  
  window.highlightedLocation = null;
  updateHighlight(null);
  tooltip.style("display", "none");
  
  // Reset all map markers and close tooltips
  if (window.markersBySite) {
    Object.values(window.markersBySite).forEach(marker => {
      const el = marker.getElement();
      if (el) el.style.opacity = '1';
      marker.closeTooltip(); // Add this line
    });
  }
})

  // ===================================================
  // HIGHLIGHT UPDATE FUNCTION
  // Shows/hides colored lines based on which location is active
  // ===================================================
function updateHighlight(location) {
  if (location) {
    const safeName = location.replace(/\s+/g, '-');

    // Hide all colored lines/dots
    svg.selectAll(`.line-color`).attr("opacity", 0);
    svg.selectAll(`.dot-color`).attr("opacity", 0);

    // Show the selected line and its dots
    svg.selectAll(`.line-color.line-${safeName}`).attr("opacity", 1);
    svg.selectAll(`.dot-color.dot-${safeName}`).attr("opacity", 1);
  } else {
    // No highlight - hide all colored lines/dots
    svg.selectAll(`.line-color`).attr("opacity", 0);
    svg.selectAll(`.dot-color`).attr("opacity", 0);
  }
}

  // ===================================================
  // MAKE UPDATE FUNCTION GLOBALLY ACCESSIBLE
  // This allows the map to call this function when markers are hovered
  // ===================================================
  window.updateRecruitmentPlotHighlight = updateHighlight;

  // ===================================================
  // CHECK IF A SITE IS ALREADY SELECTED
  // If user clicked a site before the plot loaded, highlight it now
  // ===================================================
  if (window.selectedSite) {
    updateHighlight(window.selectedSite);
  }

  return svg.node();
}
```
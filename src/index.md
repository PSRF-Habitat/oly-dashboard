---
toc: false
theme: dashboard
---

# Olympia Oysters! 🦪

---
<!-- ===================================================== -->
<!-- Page grid layout -->
<!-- ===================================================== -->
<div class="grid grid-cols-2">
  
  <!-- Map card -->
  <div class="card grid-rowspan-2">
    ${resize((width) => oysterMap(enh_sites, {width}))}
  </div>
  
  <!-- Top right card --> 
  <div class="card">
    ${resize((width) => densityPlot(ann_densities, {width}))}
  </div>
  
  <!-- Bottom right card --> 
  <div class="card">

## Data Viz here

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

// Salish Sea coordinates for map placement
const center = [47.8, -123.5];
const zoom = 8;

// Site names with story details (EXAMPLES FOR NOW - UPDATE LATER)
const sitesWithDetails = ["Port Gamble Bay", "Quilcene Bay"];

// Function to build map
function oysterMap(data, {width} = {}) {
  
// ==========================================================
// BUILD CONTAINERS
// ==========================================================

  // Create main container to hold both map and story details ----
  const mainContainer = document.createElement("div");
  // Style main container
  Object.assign(mainContainer.style, { // Wrapping in Object.assign is cleaner syntax for applying all the styling together
    width: `${width}px`,  // Dynamic width will change with page resizing
    height: "800px",      // Set height
  });

  // Create map container ----
  const mapContainer = document.createElement("div");
  // Style map container
  Object.assign(mapContainer.style, {
    width: "100%",   // Fill full width of parent (mainContainer)
    height: "100%",  // Fill full height of parent (800px)
    borderRadius: "8px",  // Round the corners
    transition: "all 0.25s ease-in-out"  // Animate style changes smoothly over 0.25 seconds
  });

  // Create story details container (hidden until site icon clicked) ----
  const detailContainer = document.createElement("div");
  // Style story container
  Object.assign(detailContainer.style, {
    display: "none",            // Hide completely (not rendered in layout)
    width: "60%",               // Width is 40|60 with map when clicked
    height: "100%",             // Full height of parent (800px)
    padding: "20px",            // Inner spacing around content
    backgroundColor: "white",   // Background color
    borderRadius: "8px",        // Round the corners
    transition: "all 1s ease-in-out",  // Animate all style changes over 1 second
    opacity: "0",               // Invisible (for fade-in effect when shown)
    overflowY: "auto",          // Enable vertical scrolling if content is tall
    overflowX: "hidden",        // Prevent horizontal scrolling
    boxSizing: "border-box"     // Include padding in height calculation (prevents overflow)
  });

  // Add map and detail containers to main container ----
  mainContainer.appendChild(mapContainer);
  mainContainer.appendChild(detailContainer);

  // Create map ----
  const map = L.map(mapContainer, {
    center: center,  // Center on coordinates established above
    zoom: zoom,      // Zoom set above as well
  });
  
  // Add Basemap (CartoDB Positron) ----
  L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
    attribution: '© OpenStreetMap © CartoDB',  // Required to show
    maxZoom: 15  // How much zoom to allow
  }).addTo(map);

  // Function to show story detail view when clicking on marker ----
  function showDetail(site) {

    // Switch to side-by-side layout
    mainContainer.style.display = "flex";  // Flexbox enables side-by-side positioning
    mainContainer.style.gap = "10px";      // 10px space between map and detail panel
    
    // Shrink map to 40% width on left side
    mapContainer.style.width = "40%";
    mapContainer.style.flexShrink = "0";  // Prevent map from shrinking further
    
    // Show detail panel at 60% width on right side
    detailContainer.style.display = "block";  // Make it visible in the layout

    // Fade in story panel (wait 10ms for display change to register, then fade)
    setTimeout(() => detailContainer.style.opacity = "1", 10);

    // Wait for layout transition to complete, then recalculate map size and center on site
    setTimeout(() => {
      map.invalidateSize();  // Tell Leaflet the container size changed
      // Recenter the map on the selected site at zoom level 12
      map.setView([site.enhancement_latitude_est, site.enhancement_longitude_est], 12, {animate: false});
    }, 250);  // 250ms matches the transition duration

    // Create button to close story view and return to full map ----
    const backButton = document.createElement("button");
    // Add text to button
    backButton.textContent = "← Back to Map";
    // Style button
    Object.assign(backButton.style, {
      marginBottom: "20px",      // Space between bottom of button and text below
      padding: "8px 16px",       // Space from button text to button box edge
      cursor: "pointer",         // Change cursor to pointer on hover
      border: "1px solid #ccc",  // Light gray border
      borderRadius: "4px",       // Slightly round corners
      backgroundColor: "#f5f5f5" // Light gray background
    });
    // Reset map when clicked using custom function resetView defined below
    backButton.onclick = resetView;

    // Clear and populate story detail panel ----
    detailContainer.innerHTML = "";              // Clear any existing content
    detailContainer.appendChild(backButton);     // Add back button at top

    // List of site images (EXAMPLES - UPDATE LATER)
    const siteImages = {
      "Port Gamble Bay": [  // Name needs to match site_name in CSV exactly
        FileAttachment("data/images/oly_sample_pic.jpg").href,    // First image
        FileAttachment("data/images/beach_sample_pic.jpg").href   // Second image
      ]
    };

    // Grab images for current site (empty array if none found)
    const photos = siteImages[site.site_name] || [];

    // Create story content container
    const content = document.createElement("div");

    // Build carousel HTML if photos exist
    // This uses a ternary operator: condition ? valueIfTrue : valueIfFalse
    const carouselHTML = photos.length > 0 ? `
      <div class="carousel">
        <!-- Left arrow button to go to previous image -->
        <button class="carousel-btn prev">‹</button>
    
        <!-- Container for all images (stacked, only one visible at a time) -->
        <div class="carousel-images">
          ${
            // Use JavaScript inside template literal with ${}
            photos.map((url, i) => 
              // .map() transforms each photo URL into an HTML img tag
              
              `<img 
                src="${url}"                                      // Image source path
                class="carousel-image ${i === 0 ? 'active' : ''}" 
              >`
              // CSS classes: always gets "carousel-image"
              // First image (i === 0) also gets "active" class to show it initially
              // Other images get no extra class (hidden by default with opacity: 0)
            ).join('')
            // .join('') combines array of img tags into single string with no separators
            // Without join: ["<img...>", "<img...>"] 
            // With join(''): "<img...><img...>"
          }
        </div>
    
        <!-- Right arrow button to go to next image -->
        <button class="carousel-btn next">›</button>
    
        <!-- Container for dot navigation (dots added by JavaScript below) -->
        <div class="carousel-dots"></div>
      </div>
    ` 
    : 
    // If photos.length is 0 (no photos for this site), create this instead:
    '';  // Empty string (nothing added to page)

    // Build full content with site name, carousel, and story text
    content.innerHTML = `
      <h2>${site.site_name}</h2>
      ${carouselHTML}
      <h3>About this site (catchy header)</h3>
      <p>Story about the site</p>
    `;
    
    // Add content to detail container
    detailContainer.appendChild(content);  // FIXED: removed duplicate line
  
    // Add carousel functionality if photos exist
    if (photos.length > 0) {
      // Get all carousel images and dots container
      const images = content.querySelectorAll('.carousel-image');
      const dotsContainer = content.querySelector('.carousel-dots');
      let currentIndex = 0;  // Track which image is currently showing
    
      // Create navigation dots (one dot per image)
      images.forEach((_, index) => {
        const dot = document.createElement('span');
        dot.className = 'carousel-dot' + (index === 0 ? ' active' : '');  // First dot is active
        dot.onclick = () => showImage(index);  // Clicking dot shows that image
        dotsContainer.appendChild(dot);
      });
    
      // Get all dots after they've been added
      const dots = content.querySelectorAll('.carousel-dot');
    
      // Function to show a specific image by index
      function showImage(index) {
        images[currentIndex].classList.remove('active');  // Hide current image
        dots[currentIndex].classList.remove('active');    // Deactivate current dot
        currentIndex = index;                             // Update current index
        images[currentIndex].classList.add('active');     // Show new image
        dots[currentIndex].classList.add('active');       // Activate new dot
      }
    
      // Previous button - go to previous image (wraps around to end)
      content.querySelector('.prev').onclick = () => {
        // Calculate previous index: (current - 1 + total) % total
        // The + total ensures we don't get negative numbers
        const newIndex = (currentIndex - 1 + images.length) % images.length;
        showImage(newIndex);
      };
    
      // Next button - go to next image (wraps around to beginning)
      content.querySelector('.next').onclick = () => {
        // Calculate next index: (current + 1) % total
        // % (modulo) makes it wrap back to 0 after the last image
        const newIndex = (currentIndex + 1) % images.length;
        showImage(newIndex);
      };
    }
  }

  // Function to reset to full map view (called when back button clicked)
  function resetView() {
    // Fade out detail panel first
    detailContainer.style.opacity = "0";
  
    // Wait for fade out animation, then reset layout
    setTimeout(() => {
      mainContainer.style.display = "block";  // Switch from flex back to block layout
    
      // Expand map back to full width and height
      Object.assign(mapContainer.style, {
        width: "100%",
        height: "100%"
      });
    
      // Hide detail panel completely
      detailContainer.style.display = "none";
    
      // Wait for layout to settle, then recalculate map size and zoom out
      setTimeout(() => {
        map.invalidateSize();  // Tell Leaflet the container size changed
        map.setView(center, zoom, {animate: false});  // Return to overview position
      
        // Reset all marker tooltips back to hover-only mode
        map.eachLayer((layer) => {
          if (layer instanceof L.Marker && layer.getTooltip()) {
            const tooltipContent = layer.getTooltip().getContent();  // Get existing tooltip text
            layer.unbindTooltip();  // Remove old tooltip
            layer.bindTooltip(tooltipContent, {  // Add new tooltip with same content
              direction: 'top',
              permanent: false  // Back to hover-only (not pinned)
            });
          }
        });
      }, 250);  // Match transition duration
    }, 250);  // Match transition duration
  }
  
  // Add markers for each enhancement site
  data.forEach(site => {
    // Check if this site has detailed story content
    const hasDetails = sitesWithDetails.includes(site.site_name);
  
    // Create marker at site coordinates
    const marker = L.marker([site.enhancement_latitude_est, site.enhancement_longitude_est])
      // Add tooltip that shows on hover
      .bindTooltip(`
        <strong>${site.site_name}</strong>${hasDetails ? ' 📖' : ''}<br>
        Type: ${site.enhancement_type}<br>
        Years: ${site.enhancement_years}
        ${hasDetails ? '<br><em style="color: #007bff; font-size: 11px;">▶ Click for more details</em>' : ''}
      `, {
        direction: 'top',     // Show tooltip above marker
        permanent: false      // Only show on hover (not always visible)
      })
      .addTo(map);  // Add marker to map
  
    // If site has details, make it clickable
    if (hasDetails) {
      // Click marker to open detail view directly
      marker.on('click', () => {
        // Make tooltip permanent when detail view opens (so it stays visible)
        marker.unbindTooltip();  // Remove old hover tooltip
        marker.bindTooltip(`
          <strong>${site.site_name}</strong> 📖<br>
          Type: ${site.enhancement_type}<br>
          Years: ${site.enhancement_years}
        `, {
          direction: 'top',
          permanent: true  // Keep it visible even when not hovering
        }).openTooltip();  // Show the tooltip immediately
      
        showDetail(site);  // Open the story detail panel
      });
    }
  });
  
  // Add scale control (shows map scale in miles and kilometers)
  L.control.scale({imperial: true, metric: true}).addTo(map);
  
  // Allow page to render before loading map details
  // This ensures the container has proper dimensions before Leaflet initializes
  setTimeout(() => map.invalidateSize(), 100);
  
  // Return the main container to be inserted into the page
  return mainContainer;
}
```

<!-- CSS Styles -->
<!-- Load Leaflet's required CSS -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/leaflet@1.9.4/dist/leaflet.css" /> 

<style>  
  /* Inheret map font from main page styles */
  .leaflet-container {
    font-family: inherit; 
  }
  /* Make required leaflet attribution more subtle & prettier */
  .leaflet-control-attribution {
    background-color: rgba(255, 255, 255, 0.7);
    font-size: 10px; 
    opacity: 0.6;
    padding: 2px 5px;
  }
  .leaflet-control-attribution:hover {
    opacity: 1;
  }
   /* Carousel styling */
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
  height: 300px;
}

.carousel-image {
  position: absolute;
  width: 100%;
  height: 100%;
  object-fit: cover;
  opacity: 0;
  transition: opacity 0.3s ease;
  pointer-events: none;
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

.carousel-btn:hover {
  background: rgba(255, 255, 255, 1);
}

.carousel-btn.prev {
  left: 10px;
}

.carousel-btn.next {
  right: 10px;
}

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

.carousel-dot.active {
  background: rgba(255, 255, 255, 1);
}

.carousel-dot:hover {
  background: rgba(255, 255, 255, 0.8);
}
</style>
<!-- END map build -->

<!-- ===================================================== -->
<!-- Build Population Estimate Plot -->
<!-- ===================================================== -->

<!-- For now, this is going to be an average annual density per m2, until I can talk with HH about project area sizes for estimating pop size -->

```js
// Load annual density data
const ann_densities = await FileAttachment("data/assessments.csv").csv({typed: true});

// Load Observable Plot library
import * as Plot from "npm:@observablehq/plot";

// Create a mutable state for selected location
const selectedLocation = Mutable(null);

// Build density plot
function densityPlot(data, {width, selectedLocation} = {}) {
  return Plot.plot({
    title: "Annual Olympia Oyster Density",
    width,
    height: 400,
    marginLeft: 50,
    marginRight: 20,
    marginTop: 30,
    marginBottom: 40,
    x: {
      label: "Year",
      tickFormat: "d",
      ticks: 5 
    },
    y: {
      label: "Density (m⁻²)",
      grid: true
    },
    color: {legend: true},
    marks: [
      Plot.line(data, {
        x: "year",
        y: "density",
        stroke: "location",
        strokeWidth: 2,
        opacity: d => selectedLocation && selectedLocation !== d.location ? 0.2 : 1
      }),
      Plot.dot(data, {
        x: "year", 
        y: "density", 
        fill: "location",
        r: 5,
        opacity: d => selectedLocation && selectedLocation !== d.location ? 0.2 : 1,
        stroke: "white",
        strokeWidth: 1
      }),
      Plot.tip(data, Plot.pointer({
        x: "year",
        y: "density",
        fill: "location",
        title: d => `${d.location}\nYear: ${d.year}\nDensity: ${d.density.toFixed(2)} m⁻²`
      }))
    ]
  });
}
```

<!-- END Population Estimate Plot Build -->

<!-- ===================================================== -->
<!-- Build Recruitment Index Timeseries Plot -->
<!-- ===================================================== -->




<!-- END Recruitment Index Timeseries Plot Build -->


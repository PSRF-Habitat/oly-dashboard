---
toc: false
title: "No recruitment grouping - size & color"
theme: dashboard
header: "<a href='https://restorationfund.org'><img src='data/images/logo-transwhite.png' alt='Logo' style='height: 120px;'></a>"
pager: false
---

<!-- =================================================== -->
<!-- Header & footer syling -->
<!-- =================================================== -->
<style>
  /* Header */
  #observablehq-header {
    position: absolute;
    background-color: #045B4C;
    height: 150px;
    align-items: center;
    padding: 0 30px;
  }

  /* Space below header so page content doesn't overlap */
  body {
    padding-top: 80px;
    padding-left: 40px;
    padding-right:40px;
  }

/* Footer */
  #observablehq-footer {
    position: absolute;
    background-color: #5A5A5A;
    align-items: center;
    width: 100%;
    left: 0;
    padding: 0 30px;
    box-sizing: border-box;
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
    <span class="big" style="color: #045B4C">141.3</span>
  </div>
  <div class="card" style="text-align: center;">
    <h1 class="muted">Sites Visited</h1>
    <span class="big" style="color: #045B4C">777</span>
  </div>
  <div class="card" style="text-align: center;">
    <h1 class="muted">Some Other</h1>
    <span class="big" style="color: #045B4C">222</span>
  </div>
  <div class="card" style="text-align: center;">
    <h1 class="muted">Catchy Facts</h1>
    <span class="big" style="color: #045B4C">999</span>
  </div>
</div>
<!-- =================================================== -->
<!-- END Cards with flashy facts -->
<!-- =================================================== -->

---

```html

<div style="
  background: #FFFFFF;
  border: 1px solid #DFDFE0;
  border-radius: 16px;
  padding: 2rem;
  margin: 1rem 0 2rem 0;
">

  <div style="
    display: grid;
    grid-template-columns: 1.3fr 1fr;
    gap: 2rem;
    align-items: start;
  ">

    <!-- LEFT -->
    <div>

      <h1 style="margin-top:0;">
        Olympia Oyster Restoration in Puget Sound
      </h1>

      <p>
        The Olympia oyster is Puget Sound's only native oyster — and by the early 1900s,
        it had nearly disappeared due to overharvesting, habitat loss, and pollution.
        Puget Sound Restoration Fund has been working to bring them back,
        one beach at a time.
      </p>

    </div>

    <!-- RIGHT -->
    <div>

      <div class="intro-card intro-card--enhancement" style="margin-bottom:1rem;">
        <div class="intro-card-label" style="color:#4e79a7; font-size:1rem;">Enhancement Sites</div>
        <p>
          Places where we've actively restored oyster habitat by adding shell, juvenile, or adult oysters.
        </p>
      </div>

      <div class="intro-card intro-card--recruitment">
        <div class="intro-card-label" style="color:#c0392b; font-size:1rem;">Recruitment Monitoring</div>
        <p>
          Annual monitoring of juvenile oyster settlement across Puget Sound.
        </p>
      </div>

    </div>

  </div>

  <div class="intro-tip">
  💡 Use the <strong>Enhancement</strong> and <strong>Recruitment</strong> tabs in the panel on the left to switch between views. Click any site or station on the map to learn more. <span style="color:#E1975C; font-weight:600;">Orange dots</span> have full stories — select one from the dropdown or click it directly.
</div>


</div>

```

```js
// ===================================================
// LOAD DATA
// ===================================================

// Enhancement sites metadata for map points and tooltips
const enh_sites_metadata = await FileAttachment("data/enhancement_sites_metadata.csv").csv({typed: true});

// Recruitment data
const recruitment_data = (await FileAttachment("data/recruitment.csv").csv({typed: true}))
    .map(d => ({...d, index: (d.index === "NA" || d.index === null || d.index === "") ? null : +d.index}));

// Data for timeline
const timeline_data = await FileAttachment("data/timeline_data.csv").csv({typed: true});

// Fidalgo Bay population estimates
const fidalgo_pop_est = await FileAttachment("data/fidalgo_population_estimates.csv").csv({typed: true});

// Fidalgo Bay shell height
const fidalgo_heights = await FileAttachment("data/fidalgo_heights_2023.csv").csv({typed: true});

// Oyster Bay population estimates
const oysterbay_pop_est = await FileAttachment("data/oysterbay_population_estimates.csv").csv({typed: true});

// Oyster Bay shell height
const oysterbay_heights = await FileAttachment("data/oysterbay_2026_heights.csv").csv({typed: true});

// ===================================================
// IMPORT LIBRARIES
// ===================================================
import * as L from "npm:leaflet@1.9.4";

// ===================================================
// SET GLOBAL STATES
// ===================================================
window.selectedSite = null;
window.markersBySite = {};

// ===================================================
// MAP CONFIGURATION
// Where to center and zoom map to
// ===================================================
const center = [47.85, -122.7];
const zoom = 8;

// ===================================================
// SITES THAT HAVE FULL STORY PANELS
// This is a list of all sites that have a written story
// To add a new story site, add its name here AND
// add a case in buildSitePanel() below.
// ===================================================
const story_sites = new Set([
  "Fidalgo Bay",
  "Oyster Bay",
  //   "Silverdale",
  //   "Chico Bay",
  // Add more here as stories are written
]);

// ===================================================
// TOOLTIP PHOTOS
// ===================================================
const tooltipPhotos = {
  "Port Gamble Bay":  FileAttachment("data/images/portgamble_tooltip.jpg").href,
  "Quilcene Bay":     FileAttachment("data/images/quilcene_tooltip.jpg").href,
  "Sinclair Inlet":   FileAttachment("data/images/sinclair_tooltip.jpg").href,
  "Legion Park":      FileAttachment("data/images/legion_SAMPLE_tooltip.jpg").href,
  "Fidalgo Bay":      FileAttachment("data/images/fidalgo_tooltip.jpeg").href,
  "Chico Bay":        FileAttachment("data/images/chicobay_tooltip.jpg").href,
  "Dogfish Bay":      FileAttachment("data/images/dogfish_tooltip.jpg").href,
  "Kiket and Lone Tree Lagoons": FileAttachment("data/images/lonetree.jpg").href,
  "Liberty Bay":      FileAttachment("data/images/libertybay_tooltip.jpg").href,
  "Oyster Bay":       FileAttachment("data/images/oysterbay_tooltip.jpg").href,
  "Samish Bay":       FileAttachment("data/images/samish_tooltip.jpg").href,
  "Scanida":          FileAttachment("data/images/scandia_tooltip.jpg").href,
  "Silverdale":       FileAttachment("data/images/silverdale_tooltip.jpg").href,
  "Smith Cove":       FileAttachment("data/images/smithcove_tooltip.jpg").href,
  "Drayton Harbor":   FileAttachment("data/images/drayton_tooltip.jpg").href,
  // Add more here
};

// ===================================================
// ===================================================
// MAP ICONS
// - Enhancement sites
// - Enhancement sites with stories
// - Recruitment stations
// ===================================================
// ===================================================

// --- Enhancement: standard (blue circle) ---
const enhancementIcon = L.divIcon({
  className: '',  // empty so Leaflet doesn't add default styles
  html: `<div style="
    background-color: #4e79a7;
    width: 14px;
    height: 14px;
    border-radius: 50%;
    border: 2px solid white;
    box-shadow: 0 0 4px #939393;
  "></div>`,
  iconSize: [18, 18],
  iconAnchor: [9, 9]
});

// --- Enhancement: story site (purple circle) ---
// Distinguishing visually sites with stories
const enhancementStoryIcon = L.divIcon({
  className: '',
  html: `<div style="
    background-color: #EE934F;
    width: 14px;
    height: 14px;
    border-radius: 50%;
    border: 2px solid white;
    box-shadow: 0 0 4px #939393;
  "></div>`,
  iconSize: [18, 18],
  iconAnchor: [9, 9]
});

// ===================================================
// ===================================================
// SHARED FUNCTION: CAROUSEL
// Used by every site panel that has photos
// Pass the container div and an array of image URLs
// Creates scroll buttons and dots for photo count
// ===================================================
// ===================================================
function buildCarousel(container, photos) {
    // If no photos, leave the container empty
    if(!photos || photos.length === 0) return;

    container.innerHTML = `
        <div class="carousel" style="margin-bottom: 32px;">
            <!-- Previous photo button -->
            <button class="carousel-btn prev">‹</button>

            <div class="carousel-images">
                ${photos.map((url, i) =>
                  // For each photo URL, it creates an <img> tag.
                  // The first image gets the class "active" (i === 0 means index is 0)
                  `<img src="${url}" class="carousel-image ${i === 0 ? 'active' : ''}">`
                // Stitch all the generated <img> strings together
                ).join('')}
            </div>

            <!-- Next photo button -->
            <button class="carousel-btn next">›</button>

            <div class="carousel-dots"></div>
         </div>
    `;
    // Find all <img> elements inside this container that have the class "carousel-image"
    const images = container.querySelectorAll('.carousel-image');

    const dotsContainer = container.querySelector('.carousel-dots');

    // Track which image is currently showing. Starts at 0 (the first image)
    let currentIndex = 0;

    // Loop over each image by its index to create one dot per photo
    images.forEach((_, i) => {
        const dot = document.createElement('span');
        // This is a shorthand for if/else: condition ? value_if_true : value_if_false
        // Same as: if i == 0: 'carousel-dot active' else: 'carousel-dot'
        dot.className = 'carousel-dot' + (i === 0 ? ' active' : '');

        // When this dot is clicked, call showImage() with this dot's index
        dot.onclick = () => showImage(i);

        // Add the dot element to the dots container div on the page.
        dotsContainer.appendChild(dot);
    });

    const dots = container.querySelectorAll('.carousel-dot');

    // ----------------------------------------------
    // Function to switch which image is visible, called when prev or next is clicked
    // ----------------------------------------------   
    function showImage(index) {
        // Remove active class from whicever image is currently showing
        images[currentIndex].classList.remove('active');

        // Also remove active from currently lit up dot
        dots[currentIndex].classList.remove('active');

        // Update currentIndex to the new image we want to show
        currentIndex = index;

        // Add active class to the new image
        images[currentIndex].classList.add('active');

        // Also add active class to the new dot
        dots[currentIndex].classList.add('active');
    }

    // Wire up the prev button (.onclick sets what happens when it's clicked)
    container.querySelector('.prev').onclick = () => {
        // Wraps around, so if we are on 0 and go back it will go to the last image
        showImage((currentIndex - 1 + images.length) % images.length);
    };

    // Wire up the next button
    container.querySelector('.next').onclick = () => {
        showImage((currentIndex + 1) % images.length);
    };
} // END CAROUSEL BUILDER FUNCTION


// ===================================================
// ===================================================
// SHARED FUNCTION: SHELL HEIGHT HISTOGRAM
// Same chart for all sites that have size data
// Pass in an array of shell height measurments 
// ===================================================
// ===================================================
function createShellHeightHistogram(sizeData) {
    if (!sizeData || sizeData.length === 0) {
        // If there is no size data, return nothing
        return null;
    }

    return Plot.plot({
        height: 280,
        marginLeft: 50,
        marginRight: 20,
        marginTop: 20,
        marginBottom: 50,

        x: {
          label: "Shell height (mm)",
          nice: true  
        },
        y: {
          label: "Count",
          grid: true  
        },
        marks: [
            Plot.rectY(
                sizeData,
                Plot.binX(
                    { y: "count" },
                    {
                        x: "height_mm",
                        fill: "#045B4C",
                        fillOpacity: 0.8,
                        thresholds: 20
                    }
                )
            ),
            Plot.ruleY([0]),

            // Add in interactivity
            // Tooltip will tell you the range of sizes in each bin, and the count in that range
            Plot.tip(sizeData, Plot.pointerX(Plot.binX(
            { y: "count" },
            {
                x: "height_mm",
                thresholds: 20
            }
        )))
        ],
        style: {
            fontFamily: "inherit",
            fontSize: "14px"
        }
    });
} // END SHELL HEIGHT HISTOGRAM BUILDER FUNCTION

// ===================================================
// ===================================================
// SHARED FUNCTION: ENHANCEMENT TIMELINE
// TBD if this will be used - needs to be workshopped
// ===================================================
// ===================================================
function createEnhancementTimeline(data, selectedSite) {

    // Filter data to the selected site
    const siteData = data.filter(d => d.site === selectedSite && d.year);

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
            fontSize: "16px",
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
                text: "label",
                fill: "#333",
                lineWidth: 12,
                fontSize: 14,
                textAnchor: "middle"
            }),

            // Tooltip on the dots showing the full description
            Plot.tip(preparedData, Plot.pointer({
                x: "year",
                y: (d, i) => i % 2 === 0
                    ? (d.tickHeight + d.numberOfLines * 13 + 5) / 2   // midpoint of above-line events
                    : -(d.tickHeight + d.numberOfLines * 13 + 5) / 2, // midpoint of below-line events
                title: d => `${d.year}: ${d.label}\n${'─'.repeat(20)}\n${d.description}`,
              //  fill: "white",
                stroke: "#e0e0e0",
                strokeWidth: 1,
                padding: 12,
                textPadding: 8,
                lineHeight: 1.2,
                fontSize: 14, 
                fontFamily: "inherit",
                maxWidth: 140,        // wraps text at 240px — key for readability
            }))
        ]
    });
} // END TIMELINE BUILDER FUNCTION

// ===================================================
// ===================================================
// SHARED FUNCTION: TOOLTIP CONTENT BUILDER
// Builds HTML string for enhancement marker tooltip.
// 3 cases:
//      1. Story site: includes 'click to explore' banner
//      2. Non-story site: no banner
//      3. No timeline data: photo only + note
// ===================================================
// ===================================================
function buildTooltipHTML(site, timelineData, isStorySite, photoUrl) {

    // --- PHOTO BLOCK ---
    // Full width image at top of tooltip
    // If no photo exists, render nothing
    const photoHTML = photoUrl ? `
        <img src="${photoUrl}" style="
            width: 100%; height: 130px; object-fit: cover;
            display: block;">
    ` : "";

    // --- Meta Rows ---
    // Total acres
    // Grab only rows for this site
    const siteRows = timelineData
        .filter(d => d.site === site.site_name && d.year)  // skip rows with no year
        .sort((a, b) => a.year - b.year);                  // sort oldest to newest
        
    // Add up acres column from timeline data
    const totalAcres = siteRows.reduce((sum, d) => {
        const val = parseFloat(d.acres);
        return sum + (isNaN(val) ? 0 : val);
    }, 0);

    // Only show total acres line if there is a value, else -
    const acresDisplay = totalAcres > 0
        ? `${totalAcres.toFixed(2)} acres enhanced`
        : "—"; 

    // Enhancement types
    const typeDisplay = site.enhancement_actions
        ? site.enhancement_actions.split(',').map(t => t.trim()).join(' · ')
        : "—";
    
    // HTML styling for these rows
    const metaHTML = `
    <div style="display:flex; align-items:center; gap:6px;
        font-size:12px; color:#555; margin-bottom:4px;">
        <span style="color:#045B4C; font-weight:600; font-size:11px; 
            text-transform:uppercase; letter-spacing:0.4px; flex-shrink:0;">Area</span>
        ${acresDisplay}
    </div>
    <div style="display:flex; align-items:center; gap:6px;
        font-size:12px; color:#555; margin-bottom:4px;">
        <span style="color:#045B4C; font-weight:600; font-size:11px;
            text-transform:uppercase; letter-spacing:0.4px; flex-shrink:0;">Type</span>
        ${typeDisplay}
    </div>
    `;

    // --- Timeline rows ---
    // Story sites: show up to 4 rows, then a "more on site page" hint to click
    // Non-story sites: show all rows bc tooltip is the full story
    // No timeline info at all: No data note
    let timelineHTML = "";

    if (siteRows.length === 0) {
        // Fallback for no timeline data recorded for this site
        timelineHTML = `
            <p style="font-size:12px; color:#999; font-style:italic; margin:0;">
                No timeline data recorded
            </p>
        `;
    } else {
        // Cap at 4 rows for story sites, show all for non-story
        const visibleRows = isStorySite ? siteRows.slice(0, 4) : siteRows;
        const hiddenCount = siteRows.length - visibleRows.length;

        // Build one row per visible timeline entry
        const rowsHTML = visibleRows.map(d => `
            <div style="display:flex; align-items:baseline; gap:8px;
                font-size:12px; margin-bottom:5px;">
                <span style="color:#045B4C; font-weight:600;
                    min-width:34px; flex-shrink:0;">${d.year}</span>
                <span style="color:#ccc; font-size:10px; flex-shrink:0;">●</span>
                <span style="line-height:1.4; color:#444;">${d.label}</span>
            </div>
        `).join('');

        // "More actions" nudge when rows were cut for story site
        const moreHint = hiddenCount > 0 ? `
            <p style="font-size:11px; color:#999; font-style:italic; margin:4px 0 0 0;">
                + ${hiddenCount} more action${hiddenCount > 1 ? 's' : ''} on site page
            </p>
        ` : "";

        timelineHTML = `
            <p style="font-size:11px; font-weight:600; color:#045B4C;
                text-transform:uppercase; letter-spacing:0.5px; margin:0 0 7px 0;">
                Enhancement history
            </p>
            ${rowsHTML}
            ${moreHint}
        `;
    }

    // --- Explore banner ---
    // Only for story sites, telling user they can click
    const exploreBanner = isStorySite ? `
        <div style="margin-top:10px; padding:7px 10px;
            background:#f0f7f5; border-radius:6px;
            font-size:12px; font-weight:600; color:#045B4C; text-align:center;">
            &#x25B6; Click to explore this site
        </div>
    ` : "";

    // --- Assemble full tooltip ---
    return `
        <div style="min-width:240px; max-width:260px;">
            ${photoHTML}
            <div style="padding:12px;">
                <p style="font-size:15px; font-weight:600; color:#222;
                    text-align:center; margin:0 0 10px 0;">
                    ${site.site_name}
                </p>
                ${metaHTML}
                <div style="height:1px; background:#e8e8e8; margin:8px 0;"></div>
                ${timelineHTML}
                ${exploreBanner}
            </div>
        </div>
    `;
} // END TOOLTIP CONTENT BUILDER FUNCTION

// ===================================================
// ===================================================
// SITE PANEL BUILDER 
//
// TO ADD A NEW STORY SITE:
//   1. Add its name to story_sites set at the top
//   2. Add a case here pointing to a new "builder" function
//   3. Write the builder function below as we want the site panel to look
// ===================================================
// ===================================================
function buildSitePanel(siteName) {
  switch (siteName) {
    case "Fidalgo Bay":  return buildFidalgoBayPanel();
    case "Oyster Bay":  return buildOysterBayPanel();
    // case "Silverdale":   return buildSilverdalePanel();
    // case "Chico Bay":    return buildChicoBayPanel();
    // case "Oyster Bay":   return buildOysterBayPanel();
  }
} // END BUILD SITE PANEL FUNCTION

// ===================================================
// ===================================================
//
// SITE PANEL: FIDALGO BAY
// Full story & data! Layout:
//   Title --> Carousel --> Intro quote block --> 
//   About This Site --> Our Work --> Timeline --> 
//   Results callout --> Population density plot --> 
//   Impact text --> Shell height histogram --> 
//   Looking Ahead --> Credits, Partners, Funders
//
// ===================================================
// ===================================================
function buildFidalgoBayPanel() {
    const panel = document.createElement("div");

    // --- Narrative ---
    const narrative = {
        intro: `White clouds rise from grey smokestacks, blurring a sprawling refinery into the distant silhouette of Mount Baker. A retired railroad trestle cuts across the bay like an old scar. Human ambition is written plainly on the shoreline, and yet, millions of Olympia oysters tell a remarkable success story.`,

        context: `The story of Fidalgo Bay begins with a rumor: that Olympia oysters once resided in these shallow waters. By the early 2000s, none remained, but the bay’s protected shorelines and limited predators made it an ideal candidate for restoration. In 2002, alongside a strong network of partners, we spread Pacific oyster shell covered in Olympia oyster seed beside the old trestle on the eastern shore, marking the first Olympia oyster restoration effort in northern Puget Sound.`,

        ourWork: `What followed was a years-long conversation with the bay. Additional seeded cultch were added in subsequent years. Non-seed bearing Pacific oyster shell was introduced in 2006, 2008, and 2013 to enhance the substrate and expand the area available for larval settlement. When monitoring revealed that nearly all natural recruitment was concentrated on the eastern side, likely shaped by summer current patterns, we responded by seeding the west side of the bay in 2016. In 2018, two new half-acre plots of bulk Pacific shell were added, one on each side of the bay, and the west side was seeded once more months later to give larval abundance a fresh boost.`,

        dataCallout: `Since 2002, the estimated Olympia oyster population in Fidalgo Bay has grown from roughly 50,000 to over 5.5 million - a more than hundredfold increase over two decades.`,

        impact: `Growth through the 2000s and early 2010s was steady, from the initial 50,000 seeded individuals to 240,000 by 2013. Then, something shifted. The population began to accelerate, explosive growth driven no longer by our additions, but by the Olys themselves! The last 5 years alone saw numbers nearly double, from 2.9 million in 2018 to 5.5 million in 2023.`,

        sizeContext: `While most of these individuals remain within the enhanced shell plots, the Olys are expanding into areas where we wouldn’t have expected them. In 2023, we counted over 1.2 million oysters in the marsh channels at the far southern end of the bay, well beyond the reach of any direct seeding effort. This was not only the densest aggregation observed that year, but also home to some of the largest individual Olympia oysters recorded anywhere in Puget Sound, with some measuring over 70mm.`,

        future: `Fidalgo Bay is not oly a local success story, but also the starting point for Olympia oyster restoration across the region. Adult oysters from here have been raised as hatchery broodstock, transplanted directly to new sites, and (in a particularly elegant turn) the bay itself has functioned as a natural hatchery, with post-larvae captured on Pacific oyster cultch bags transferred to other bays. Restoration efforts in Sequim Bay, Fisherman Bay on Lopez Island, Skagit and Similk Bays, Padilla Bay, Samish Bay, Chuckanut Bay, and Drayton Harbor have all been seeded by what grew here. Since 2002, approximately 3,000 bags of spat-on-shell from Fidalgo Bay broodstock have gone out to support restoration across the north Sound.`,

        partnersLead: `The story of Fidalgo Bay is, at its heart, a story showcasing the power of reiterative enhancement actions and strong community partnerships. Walk these tidelands today and you’ll find something quite extraordinary. This would not have been possible without the extensive efforts of this incredible network of partners and community members.`,

        partnersList: `Taylor Shellfish, WDFW, Skagit County Marine Resources Committee (MRC), Swinomish Indian Tribal Community, Samish Indian Nation, Northwest Straits Foundation, Rose Foundation, City of Anacortes, and many others.`
    };

    // --- Layout HTML ---
    // Some of these are placeholder divs for dynamic content like plots
    panel.innerHTML =  `
        <!-- Site title 
        <h2 style="
        font-size: 32px; font-weight: 700; color: #045B4C;
        text-align: center; margin: 0 0 24px 0;
        letter-spacing: 0.5px; line-height: 1.2;
        ">Fidalgo Bay</h2> -->

        <!-- Carousel placeholder -->
        <div id="fidalgo-carousel"></div>

        <!-- Intro quote -->
        <div style="
        font-size: 16px; line-height: 1.8; color: #333;
        margin-bottom: 32px; padding: 24px;
        background: linear-gradient(to right, #f0f7f6, transparent);
        border-left: 4px solid #045B4C; font-style: italic;
        ">${narrative.intro}</div>

        <!-- About This Site -->
        <div style="margin-bottom: 40px;">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">About</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.context}
        </p>
        </div>

        <!-- Our Work -->
        <div style="
        background: #f8f9fa; padding: 24px; border-radius: 8px; margin-bottom: 40px;
        ">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Our Work</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.ourWork}
        </p>
        </div>

         <!-- Enhancement timeline -->
        <div style="
        background: white; padding: 24px; border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08); margin-bottom: 40px;
        ">
        <h3 style="
            font-size: 16px; font-weight: 700; color: #045B4C;
            margin: 0 0 8px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Enhancement History</h3>
        <p style="font-size: 14px; color: #666; margin: 0 0 20px 0; font-style: italic;">
            Timeline of restoration actions
        </p>
        <div id="fidalgo-timeline"></div>
        </div>

        <!-- Data callout -->
        <div style="
        padding: 20px;
        background: linear-gradient(135deg, #e8f4f2 0%, #f0f7f6 100%);
        border-radius: 8px; border-left: 4px solid #045B4C; margin-bottom: 24px;
        ">
        <p style="font-size: 15px; line-height: 1.7; color: #333; margin: 0; font-weight: 500;">
            ${narrative.dataCallout}
        </p>
        </div>

        <!-- Population density plot -->
        <div style="
        background: white; padding: 24px; border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08); margin-bottom: 40px;
        ">
        <h3 style="
            font-size: 16px; font-weight: 700; color: #045B4C;
            margin: 0 0 8px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Population Size Over Time</h3>
        <p style="font-size: 14px; color: #666; margin: 0 0 20px 0; font-style: italic;">
            Estimated population size at Fidalgo Bay, 2001 to 2023
        </p>
        <div id="fidalgo-population-plot"></div>
        </div>

        <!-- Impact text -->
        <div style="margin-bottom: 40px;">
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.impact}
        </p>
        </div>

        <!-- Shell height section -->
        <div style="
        background: white; padding: 24px; border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08); margin-bottom: 24px;
        ">
        <h3 style="
            font-size: 16px; font-weight: 700; color: #045B4C;
            margin: 0 0 8px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Oyster Size Class Distribution</h3>
        <p style="font-size: 14px; color: #666; margin: 0 0 20px 0; font-style: italic;">
            Most recent distribution of individual oyster shell heights, measured 2023
        </p>
        <div id="fidalgo-size-plot"></div>
        </div>

        <!-- Size context text -->
        <div style="margin-bottom: 40px;">
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.sizeContext}
        </p>
        </div>

        <!-- Looking Ahead -->
        <div style="
        background: linear-gradient(135deg, #f0f7f6 0%, #e8f4f2 100%);
        padding: 28px; border-radius: 8px;
        border-left: 4px solid #045B4C; margin-bottom: 40px;
        ">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Looking Ahead</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.future}
        </p>
        </div>

        <!-- Partners -->
        <div style="
            border-top: 1px solid #e0e0e0;
            padding-top: 32px;
            margin-bottom: 40px;
        ">
            <h3 style="
                font-size: 14px; font-weight: 700; color: #045B4C;
                margin: 0 0 12px 0; text-transform: uppercase; letter-spacing: 0.5px;
            ">A Huge Thank You</h3>
            <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0 0 12px 0;">
                ${narrative.partnersLead}
            </p>
            <p style="font-size: 14px; line-height: 1.8; color: #666; margin: 0;">
                ${narrative.partnersList}
            </p>
        </div>
    `;

    // Insert dyanmic content (plots!!) into placeholder divs built above

    // Photos for the carousel
    const photos = [
        tooltipPhotos["Fidalgo Bay"], // First photo is the tooltip photos
        // Add more photos in like this once we have them:
        // FileAttachment("data/images/fidalgo_2.jpg").href, 
        // etc,
        // etc
        FileAttachment("data/images/fidalgo2.jpeg").href
    ].filter(Boolean);
    buildCarousel(panel.querySelector("#fidalgo-carousel"), photos);

    // Timeline
    panel.querySelector("#fidalgo-timeline")
        .appendChild(createEnhancementTimeline(timeline_data, "Fidalgo Bay"));
        
    // Population plot
    panel.querySelector("#fidalgo-population-plot")
        .appendChild(createFidalgoBayPopulationPlot(fidalgo_pop_est)); // (defined below)

    // Shell height histogram
    // Not yet 100% sure what this will look like, but this is one idea
    // const fidalgoSizeData = fidalgo_heights; // Data will go in here when we have it!! 
    // example for above: 
    // [ann_densities.filter(d => d.location === "Fidalgo Bay" && d.shell_height_mm)]
    panel.querySelector("#fidalgo-size-plot")
        .appendChild(createShellHeightHistogram(fidalgo_heights));

    return panel;
} // END BUILD FIDALGO BAY PANEL

// --- Fidlago Bay Population line chart ---
function createFidalgoBayPopulationPlot(data) {
    if (data.length === 0) {
        return null; 
    }

    const cleanData = data.filter(d => d.population_estimate != null && d.population_estimate !== "NA");

    if (cleanData.length === 0) {
        return null;
    }

    return Plot.plot({
        height: 350,
        marginLeft: 60,
        marginRight: 30,
        marginTop: 15,
        marginBottom: 30,
        insetBottom: 20,
        insetTop: 10, 
        x: {
            label: null,
            tickFormat: "d",
            tickSpacing: 60,
            padding: 0.1
        },
        y: {
            label: "Estimated Population",
            grid: true,
            padding: 0.2,
            tickFormat: d => {    // "5.5M" instead of "5,500,000-"
                if (d >= 1_000_000) return (d / 1_000_000).toFixed(1) + "M";
                if (d >= 1_000)     return (d / 1_000).toFixed(0) + "K";
                return d;
            }
        },
        marks: [
            // Soft filled area under the line
            Plot.areaY(cleanData, {
                x: "year",
                y: "population_estimate",
                fill: "#045B4C",
                fillOpacity: 0.08
            }),
            Plot.line(cleanData, {
                x: "year",
                y: "population_estimate",
                stroke: "#045B4C",
                strokeWidth: 2.5
            }),
            Plot.dot(cleanData, {
                x: "year",
                y: "population_estimate",
                fill: "#045B4C",
                stroke: "white",
                strokeWidth: 2,
                r: 4
            }),
            Plot.tip(cleanData, Plot.pointer({
                x: "year",
                y: "population_estimate",
                title: d => `${d.year}: ${d.population_estimate.toLocaleString()}`
            }))
        ],
        style: { fontFamily: "inherit", fontSize: "14px" }
    });
} // END Fidlago Bay pop line plot

// ===================================================
// ===================================================
//
// SITE PANEL: OYSTER BAY
// Layout:
//
// ===================================================
// ===================================================
function buildOysterBayPanel() {
    const panel = document.createElement("div");

    // --- Narrative ---
    const narrative = {
        intro: `In 2010, the discovery of one of the most prolific Olympia oyster beds the team had yet encountered, sitting near the mouth of Dyes Inlet in Mud Bay, offered a vivid demonstration of what this inlet could hold. Naturally, the team was anxious to know what else might be tucked away in its farther reaches. Just around the point was a place with a promising name: Oyster Bay.`,

        context: `The first visit was a strikeout. Within the tidal heights where Olys typically thrive, none were to be found. The team continued deeper into Dyes Inlet with little luck finding a bed nearly as dense as what Mud had to offer. But, PSRF’s Brian Allen couldn’t shake the hunch that they were missing something. On a whim, at a much lower tide than before, he made a return visit. There, in the center of Oyster Bay, uncovered by the receding water, was a small peninsula absolutely covered in Olympia oysters.`,

        ourWork: `In 2011, the team placed a half-acre plot of bulk Pacific oyster shell adjacent to this small but dense natural aggregation, hoping to expand available habitat and coax the population higher into the intertidal. It was one of our earliest uses of bulk shell as a restoration tool, and Oyster Bay became a place to pay close attention, and a site that would prove formative to our learning.`,

        dataCallout: `Results came quicker than expected. That following spring, the added shell was absolutely loaded with juvenile oysters, a striking early expansion that suggested something special about this bay.`, 
        
        results: `Low exposure, calm water, no major terrestrial inputs, and the kind of hydrodynamics favorable for larval retention made Oyster Bay an exceptional environment for these animals. The Olys here, as the team would come to learn, tend to dance to their own beat, recruiting strongly in years when settlement elsewhere in the Sound lays low.`,

        impact: `For the next several years, Brian returned regularly to keep an eye on things. Then, in 2020, the team returned and what they found was unexpected: the shell placed in 2011 had largely been buried into the sediment. But the oysters, they had gone everywhere. From the deep zone where they’d originally lived, the population had spread across the beach, climbing all the way up to the +1 foot elevation and filling the full normal intertidal range of the species, down to the -2 feet and perhaps even deeper. And this wasn’t a scattered population, but rather dense, semi-structured aggregations boasting more than 100 Olys per square meter in many places.`,

        restorationQuestion: `The question the team carried home was one that follows many restoration projects: did the 2011 project kick this off, or did the team act at precisely the right moment, just as a broader upswing in natural reproduction was already underway?`,

        sizeIntro: `Oyster Bay also became a classroom. In the early years of working here, the team collected some of their first systematic data on Oly size distributions within a population, data that went on to reveal a meaningful pattern. `,

        sizeContext: `Young, developing beds show a size distribution skewed toward smaller individuals, a pronounced mode associated with young-of-year recruits. Mature, established beds look more normally distributed across size classes. This insight, developed in part by careful observation at Oyster Bay, gave the team a new lens for reading the health and trajectory of populations across the Sound.`,
        
        habitatDescription: `Since the first population survey in 2011 estimated roughly 400,000 individuals in the natural aggregation, the population has doubled to over 800,000 as of 2026. But population estimates, by their nature, capture only what can be counted within a defined survey area at a fixed point in time. Walk the beach at Oyster Bay today and the numbers feel like an understatement. Olys sprawl across the substrate in dense, layered masses, spilling into areas well beyond any of our formal survey boundaries. The habitat is absolutely incredible, showing what a restored Olympia oyster bed, fully realized, looks like.`,

        closing: `Oyster Bay remains an active monitoring site, tracked through both population surveys and recruitment monitoring. The team isn’t the only ones keeping a close eye on things - a resident population of Canada geese has claimed a small island in the bay as their own, and they take their oversight role seriously (sometimes, a little too seriously). After 15 years, it has become one of the richest Olympia oyster habitats in Dyes Inlet, a quiet bay that has, by any measure, earned its name. `
    };

    // --- Layout HTML ---
    // Some of these are placeholder divs for dynamic content like plots
    panel.innerHTML =  `
        <!-- Site title 
        <h2 style="
        font-size: 32px; font-weight: 700; color: #045B4C;
        text-align: center; margin: 0 0 24px 0;
        letter-spacing: 0.5px; line-height: 1.2;
        ">Oyster Bay</h2> -->

        <!-- Carousel placeholder -->
        <div id="oysterbay-carousel"></div> 

        <!-- Intro quote -->
        <div style="
        font-size: 16px; line-height: 1.8; color: #333;
        margin-bottom: 32px; padding: 24px;
        background: linear-gradient(to right, #f0f7f6, transparent);
        border-left: 4px solid #045B4C; font-style: italic;
        ">${narrative.intro}</div>
 
        <!-- About -->
        <div style="margin-bottom: 40px;">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">About</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.context}
        </p>
        </div>
 
        <!-- Our Work -->
        <div style="
        background: #f8f9fa; padding: 24px; border-radius: 8px; margin-bottom: 40px;
        ">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Our Work</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.ourWork}
        </p>
        </div>
 
        <!-- Callout -->
        <div style="
        padding: 20px;
        background: linear-gradient(135deg, #e8f4f2 0%, #f0f7f6 100%);
        border-radius: 8px; border-left: 4px solid #045B4C; margin-bottom: 24px;
        ">
        <p style="font-size: 15px; line-height: 1.7; color: #333; margin: 0; font-weight: 500;">
            ${narrative.dataCallout}
        </p>
        </div>
 
        <!-- Rest of early results + hydrology context, plain prose -->
        <div style="margin-bottom: 40px;">
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.results}
        </p>
        </div>
 
        <!-- Impact text -->
        <div style="margin-bottom: 40px;">
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.impact}
        </p>
        </div>
 
        <!-- Population plot -->
        <div style="
        background: white; padding: 24px; border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08); margin-bottom: 24px;
        ">
        <h3 style="
            font-size: 16px; font-weight: 700; color: #045B4C;
            margin: 0 0 8px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Population Size Over Time</h3>
        <p style="font-size: 14px; color: #666; margin: 0 0 20px 0; font-style: italic;">
            Estimated population size at Oyster Bay, 2011 to 2026
        </p>
        <div id="oysterbay-population-plot"></div>
        </div>
 
        <!-- Restoration question -->
         <div style="
        background: #f8f9fa; padding: 24px; border-radius: 8px; margin-bottom: 24px;
        ">
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.restorationQuestion}
        </p>
        </div>
 
        <!-- Reading the Population -->
        <div style="margin-bottom: 40px;">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Reading the Population</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.sizeIntro}
        </p>
        </div>
 
        <!-- Size class distribution chart -->
        <div style="
        background: white; padding: 24px; border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08); margin-bottom: 24px;
        ">
        <h3 style="
            font-size: 16px; font-weight: 700; color: #045B4C;
            margin: 0 0 8px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">Oyster Size Class Distribution</h3>
        <p style="font-size: 14px; color: #666; margin: 0 0 20px 0; font-style: italic;">
            Most recent distribution of individual oyster shell heights, measured 2026
        </p>
        <div id="oysterbay-size-plot"></div>
        </div>
 
        <!-- Size context -->
        <div style="margin-bottom: 40px;">
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.sizeContext}
        </p>
        </div>
 
        <!-- The Bed Today -->
         <div style="
        background: #f8f9fa; padding: 24px; border-radius: 8px; margin-bottom: 24px;
        ">
        <h3 style="
            font-size: 18px; font-weight: 700; color: #045B4C;
            margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
        ">The Bed Today</h3>
        <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
            ${narrative.habitatDescription}
        </p>
        </div>
 
        <!-- Still Watching -->
        <div style="margin-bottom: 40px;">
            <h3 style="
                font-size: 18px; font-weight: 700; color: #045B4C;
                margin: 0 0 16px 0; text-transform: uppercase; letter-spacing: 0.5px;
            ">Still Watching</h3>
            <p style="font-size: 15px; line-height: 1.8; color: #444; margin: 0;">
                ${narrative.closing}
            </p>
        </div>
    `;

    // Insert dyanmic content (plots!!) into placeholder divs built above

    // Photos for the carousel
    const photos = [
        tooltipPhotos["Oyster Bay"], // First photo is the tooltip photos
        // Add more photos in like this once we have them:
        // FileAttachment("data/images/fidalgo_2.jpg").href, 
        // etc,
        // etc
        FileAttachment("data/images/oysterbay_enhancement.jpg").href,
        FileAttachment("data/images/oysterbay_2012.JPG").href,
        FileAttachment("data/images/oysterbay_survey_2026.jpg").href,
        FileAttachment("data/images/oysterbay_loads_of_olys_2026.HEIC").href
    ].filter(Boolean);
    buildCarousel(panel.querySelector("#oysterbay-carousel"), photos);

    // Timeline
   // panel.querySelector("#fidalgo-timeline")
   //     .appendChild(createEnhancementTimeline(timeline_data, "Fidalgo Bay"));
        
    // Population plot
   panel.querySelector("#oysterbay-population-plot")
       .appendChild(createFidalgoBayPopulationPlot(oysterbay_pop_est)); // (defined above, reusing code from Fidalgo)

    // Shell height histogram
    // Not yet 100% sure what this will look like, but this is one idea
    // const fidalgoSizeData = fidalgo_heights; // Data will go in here when we have it!! 
    // example for above: 
    // [ann_densities.filter(d => d.location === "Fidalgo Bay" && d.shell_height_mm)]
    panel.querySelector("#oysterbay-size-plot")
       .appendChild(createShellHeightHistogram(oysterbay_heights));

    return panel;
} // END BUILD OYSTER BAY PANEL


// ===================================================
// ===================================================
// YEAR SLIDER BUILDER (RECRUITMENT TAB)
//
// Creates an <input type="range"> slider for the
// recruitment tab. Could have done this using a pre-built 
// slider input, but it was harder to make it pretty that way
//
// Arguments:
//   years - Unique years in the data (array)
//   currentYear - the currently selected year
//   onChange    - callback fn(year) called on slide
// ===================================================
// ===================================================
function buildYearSlider(years, currentYear, onChange) {

    // Outer div for label + slider + year display
    const wrapper = document.createElement("div");
    // Style it
    Object.assign(wrapper.style, {
        padding: "0 4px",
        marginBottom: "20px"
    });

    // Label row: "YEAR" on the left and current selected year on right
    const labelRow = document.createElement("div");
    Object.assign(labelRow.style, {
        display: "flex",
        justifyContent: "space-between",
        alignItems: "baseline",
        marginBottom: "8px"
    });

    const label = document.createElement("span");
    label.textContent = "Year";
    Object.assign(label.style, {
        fontSize: "13px",
        fontWeight: "600",
        color: "#045B4C",
        textTransform: "uppercase",
        letterSpacing: "0.5px"
    }); 

    // The big year number shown next to the label
    const yearDisplay = document.createElement("span");
    yearDisplay.textContent = currentYear;
    Object.assign(yearDisplay.style, {
        fontSize: "18px",
        fontWeight: "700",
        color: "#045B4C",
        fontVariantNumeric: "tabular-nums"  // prevents layout jumpyness as digits change
    });

    // Place them in the container
    labelRow.appendChild(label);
    labelRow.appendChild(yearDisplay);

    // Make the actual slider
    const slider = document.createElement("input");
    slider.type = "range";
    slider.min = 0; // we are indexing into years, with 0 being the first row
    slider.max = years.length - 1;
    slider.value = years.indexOf(currentYear);
    slider.step = 1;
    Object.assign(slider.style, {
        width: "100%",
        accentColor: "#045B4C",
        cursor: "pointer"
    });

    // Min/max year labels underneath slider
    const rangeLabels = document.createElement("div");
    Object.assign(rangeLabels.style, {
        display: "flex",
        justifyContent: "space-between",
        fontSize: "11px",
        color: "#999",
        marginTop: "4px"
    });
    // Create label based on years represented in data
    rangeLabels.innerHTML = `<span>${years[0]}</span><span>${years[years.length - 1]}</span>`;

    // Update year display and map when slider moves
    slider.addEventListener("input", () => {
        const year = years[parseInt(slider.value)];
        yearDisplay.textContent = year;
        onChange(year); // this will update the map
    });

    // Put it all together
    wrapper.appendChild(labelRow);
    wrapper.appendChild(slider);
    wrapper.appendChild(rangeLabels);

    return wrapper;
} // END Year slider builder

// ===================================================
// ===================================================
// RECRUITMENT COLOR SCALE 
//
// Maps an index value to a color based on BA's established bins
// Writing as a function because it will be called each time the 
// year slider slides
//
// Bins:
//   No data: grey
//   0: pale yellow
//   0-1: light yellow
//   1-2: yellow-orange
//   2-3: orange
//   3-5: dark orange
//   5-10: red-orange
//   10-20: dark red
//   >=20: deep red
// ===================================================
// ===================================================
function spatToColor(value, maxValue) {
    // No data
    if (value === null || isNaN(value)) return "#c8c8c8";

    // Assign color by bin
    if (value === 0)        return "#ffffcc";  // 0
    if (value <= 1)         return "#ffeda0";  // 0–1
    if (value <= 2)         return "#fed976";  // 1–2
    if (value <= 3)         return "#feb24c";  // 2–3
    if (value <= 5)         return "#fd8d3c";  // 3–5
    if (value <= 10)        return "#f03b20";  // 5–10
    if (value <= 20)        return "#bd0026";  // 10–20
    return                         "#67000d";  // >=20
} // END recruitment color scale

// Circle radius scaled to index value
function spatToRadius(value) {
    if (value === null || isNaN(value)) return 5;
    if (value === 0) return 5;
    return 5 + Math.sqrt(value) * 1.8;
}

// ===================================================
// ===================================================
// RECRUITMENT STATION DETAIL PANEL
//
// Panel similar to enhancement site stories
// Pops out from right side when recruitment station clicked
// Shows line plot of recruitment over time for all sites with
// selected site highlighted
//
// Arguments:
//   station: the station row object from the CSV
//   allData: full recruitment CSV
//   detailContainer: the existing detail panel div to populate
//   map: the Leaflet map
//   mainContainer / mapContainer: for layout shift (same
//                 pattern as showDetail() in enhancement tab)
//   resetView: the existing resetView() function to reuse
// ===================================================
// ===================================================
function showRecruitmentDetail(station, allData, detailContainer, map, mainContainer, mapContainer, resetView) {

    // Filter to current station and sort by year
    const stationData = allData
        .filter(d => d.standard_station === station.standard_station && d.year && d.index != null)
        .sort((a, b) => a.year - b.year);

    // Add some summary stats
    const avgAll = stationData.reduce((s, d) => s + d.index, 0) / (stationData.length || 1);
    const maxYear = stationData.reduce((best, d) => d.index > best.index ? d : best, stationData[0]);
    const minYear = stationData.reduce((worst, d) => d.index < worst.index ? d : worst, stationData[0]);

    // -----------------------------------------------
    // Shift layout: map shrinks to 30%, panel appears
    // (same pattern to showDetail() in enhancement tab)
    // -----------------------------------------------
    mainContainer.style.display = "flex";
    mainContainer.style.gap = "10px";
    mapContainer.style.width = "30%";
    mapContainer.style.flexShrink = "0";
    detailContainer.style.display = "flex";
    setTimeout(() => detailContainer.style.opacity = "1", 10);

    setTimeout(() => {
        map.invalidateSize();
        map.setView(
            [station.latitude, parseFloat(station.longitude) + 0.02],
            13,
            { animate: false }
        );
    }, 50);

    // Clear any previously shown content
    detailContainer.innerHTML = "";

    // -----------------------------------------------
    // Button bar (non-scrolling top strip)
    // Reuses the same structure as the enhancement panel
    // -----------------------------------------------
    const buttonBar = document.createElement("div");
    Object.assign(buttonBar.style, {
        flexShrink: "0",
        padding: "16px 20px",
        borderBottom: "1px solid #e0e0e0",
        backgroundColor: "white",
        borderRadius: "8px 8px 0 0",
        zIndex: "10",
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between"
    });

    // Back button: calls the shared resetView() defined in oysterMap()
    const backButton = document.createElement("button");
    backButton.textContent = "← Back to Map";
    Object.assign(backButton.style, {
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
    backButton.onmouseenter = () => { backButton.style.backgroundColor = "#045B4C"; backButton.style.color = "white"; };
    backButton.onmouseleave = () => { backButton.style.backgroundColor = "white";   backButton.style.color = "#045B4C"; };
    backButton.onclick = resetView;

    const stationTitle = document.createElement("h2");
    stationTitle.textContent = station.standard_station;
    Object.assign(stationTitle.style, {
        margin: "0",
        fontSize: "22px",
        fontWeight: "700",
        color: "#045B4C",
        letterSpacing: "0.5px",
        textAlign: "right"
    });

    buttonBar.appendChild(backButton);
    buttonBar.appendChild(stationTitle);

    // -----------------------------------------------
    // Scrollable body
    // -----------------------------------------------
    const scrollBody = document.createElement("div");
    Object.assign(scrollBody.style, {
        flexGrow: "1",
        overflowY: "auto",
        overflowX: "hidden",
        padding: "20px",
        boxSizing: "border-box"
    });

    // Tag showing this is recruitment data (not an enhancement story)
    const tag = document.createElement("div");
    tag.textContent = "Recruitment Monitoring Station";
    Object.assign(tag.style, {
        display: "inline-block",
        fontSize: "11px",
        fontWeight: "600",
        color: "#045B4C",
        background: "#e8f4f2",
        padding: "4px 10px",
        borderRadius: "20px",
        textTransform: "uppercase",
        letterSpacing: "0.5px",
        marginBottom: "20px"
    });
    scrollBody.appendChild(tag);

    // -----------------------------------------------
    // Summary stats callout row
    // Three boxes: average, best year, worst year
    // -----------------------------------------------
    if (stationData.length > 0) {
        const statsRow = document.createElement("div");
        Object.assign(statsRow.style, {
            display: "grid",
            gridTemplateColumns: "repeat(3, 1fr)",
            gap: "10px",
            marginBottom: "28px"
        });

        const stats = [
            { label: "All-time avg",  value: avgAll.toFixed(1),          unit: "live olys / shell" },
            { label: "Best year",     value: maxYear ? maxYear.year : "—", unit: maxYear ? `${parseFloat(maxYear.index).toFixed(1)} live olys` : "" },
            { label: "Lowest year",   value: minYear ? minYear.year : "—", unit: minYear ? `${parseFloat(minYear.index).toFixed(1)} live olys` : "" }
        ];

        stats.forEach(stat => {
            const box = document.createElement("div");
            Object.assign(box.style, {
                background: "linear-gradient(135deg, #e8f4f2 0%, #f0f7f6 100%)",
                borderRadius: "8px",
                padding: "14px 12px",
                textAlign: "center"
            });
            box.innerHTML = `
                <div style="font-size:11px; font-weight:600; color:#045B4C;
                    text-transform:uppercase; letter-spacing:0.5px; margin-bottom:6px;">${stat.label}</div>
                <div style="font-size:22px; font-weight:700; color:#045B4C;
                    font-variant-numeric:tabular-nums;">${stat.value}</div>
                <div style="font-size:11px; color:#777; margin-top:3px;">${stat.unit}</div>
            `;
            statsRow.appendChild(box);
        });

        scrollBody.appendChild(statsRow);
    }

    // -----------------------------------------------
    // Comparison option: controls which sites appear as
    // grey comparison lines behind the highlighted site
    // Options: this site only, waterbody, basin, all sites
    // -----------------------------------------------

    // Label explaining what the comparison pills do
    const compareLabel = document.createElement("div");
    Object.assign(compareLabel.style, {
        fontSize: "12px",
        fontWeight: "600",
        color: "#045B4C",
        textTransform: "uppercase",
        letterSpacing: "0.5px",
        marginBottom: "6px"
    });
    compareLabel.textContent = "Compare Against";

    const compareHint = document.createElement("p");
    Object.assign(compareHint.style, {
        fontSize: "12px",
        color: "#777",
        margin: "0 0 10px 0",
        lineHeight: "1.5"
    });
    compareHint.textContent = "Use these buttons to compare the current station to other stations in the same waterbody, basin, or all of Puget Sound.";
    

    const scopeWrapper = document.createElement("div");
    Object.assign(scopeWrapper.style, {
        marginBottom: "16px",
        display: "flex",
        gap: "8px",
        flexWrap: "wrap"
    });

    const scopes = [
        { id: "station", label: "Current Station" },
        { id: "waterbody", label: `${station.waterbody} Stations` },
        { id: "basin", label: `${station.basin} Stations` || "Basin" },
        { id: "sound", label: "All Stations" }
    ];

    let currentScope = "station";

    // Build one pill button per scope
    const scopeBtns = {};
    scopes.forEach(scope => {
        const btn = document.createElement("button");
        btn.textContent = scope.label;
        Object.assign(btn.style, {
            padding: "6px 14px",
            border: "2px solid #045B4C",
            borderRadius: "20px",
            fontSize: "12px",
            fontWeight: "600",
            cursor: "pointer",
            transition: "all 0.2s ease",
            backgroundColor: scope.id === "station" ? "#045B4C" : "white",
            color: scope.id === "station" ? "white" : "#045B4C"
        });
        btn.addEventListener("click", () => {
            currentScope = scope.id;
            // Update button styles
            Object.entries(scopeBtns).forEach(([id, b]) => {
                b.style.backgroundColor = id === scope.id ? "#045B4C" : "white";
                b.style.color           = id === scope.id ? "white"   : "#045B4C";
            });
            renderChart();
        });
        scopeBtns[scope.id] = btn;
        scopeWrapper.appendChild(btn);
    });
    

    // Chart container: gets rebuilt by renderChart() on scope change
    const chartWrapper = document.createElement("div");
    Object.assign(chartWrapper.style, {
        background: "white",
        padding: "20px",
        borderRadius: "8px",
        boxShadow: "0 2px 8px rgba(0,0,0,0.08)",
        marginBottom: "24px"
    });
    scrollBody.appendChild(chartWrapper);
    scrollBody.appendChild(compareLabel);
    scrollBody.appendChild(compareHint);
    scrollBody.appendChild(scopeWrapper);

    // -----------------------------------------------
    // renderChart: builds the Plot chart for the
    // current scope. Called on load and on scope change.
    // -----------------------------------------------
    function renderChart() {
        chartWrapper.innerHTML = `
            <h3 style="font-size:15px; font-weight:700; color:#045B4C;
                margin:0 0 4px 0; text-transform:uppercase; letter-spacing:0.5px;">
                Recruitment Over Time
            </h3>
            <p style="font-size:13px; color:#666; margin:0 0 16px 0; font-style:italic;">
                Average live olys per shell per year
            </p>
        `;

        // Filter comparison sites based on selected scope
        // allData is the full recruitment dataset passed into showRecruitmentDetail
        const comparisonStations = currentScope === "station"
            ? []   // no comparison lines for "this station only"
            : allData.filter(d => {
                if (currentScope === "waterbody") 
                    return d.waterbody === station.waterbody && d.standard_station !== station.standard_station;
                if (currentScope === "basin") 
                    return d.basin === station.basin && d.standard_station !== station.standard_station;
                if (currentScope === "sound") 
                    return d.standard_station !== station.standard_station;
                return false;
            });

        // Get unique comparison station names
        const compStationNames = [...new Set(comparisonStations.map(d => d.standard_station))];

        // Build comparison line data: one array per station
        // Each array is that station's full time series
        const compLines = compStationNames.map(s =>
            allData
                .filter(d => d.standard_station === s && d.year && d.index !== null && !isNaN(d.index))
                .sort((a, b) => a.year - b.year)
        ).filter(arr => arr.length > 1);  // skip stations with only one data point

        // Compute global y-max across highlighted + comparison stations
        // Cap at 99th percentile to prevent extreme outliers messing with the scale
        const allIndexValues = [
            ...stationData.map(d => d.index),
            ...compLines.flat().map(d => d.index)
        ].filter(v => v !== null && !isNaN(v)).sort((a, b) => a - b);

        const yMax = allIndexValues[Math.floor(allIndexValues.length * 0.99)] || 10;

        // Clamp comparison line data to yMax so lines end at the plot boundary
        // rather than escaping above it. We clamp each point individually.
        const compLinesClamped = compLines.map(lineData =>
            lineData.map(d => ({...d, indexClamped: Math.min(d.index, yMax)}))
        );

        // For arrow markers: find the points in each series that exceed yMax
        const arrowPoints = compLinesClamped.flatMap(lineData =>
            lineData.filter(d => d.index > yMax)
        );
        const arrowPointsHighlighted = stationData
            .filter(d => d.index > yMax)
            .map(d => ({...d, indexClamped: yMax}));
        const allArrowPoints = [...arrowPoints, ...arrowPointsHighlighted];

        if (stationData.length > 1) {
            const chart = Plot.plot({
                height: 260,
                marginLeft: 50,
                marginRight: 20,
                marginTop: 25,
                marginBottom: 40,
                x: {
                    label: null,
                    tickFormat: "d",
                    tickSpacing: 60
                },
                y: {
                    label: "Avg live olys / shell",
                    labelAnchor: "top",
                    grid: true,
                    nice: true, 
                    domain: [0, yMax]
                },
                marks: [
                       // Comparison lines — clamped to yMax at the boundary
                    ...compLinesClamped.map(lineData =>
                        Plot.lineY(lineData, {
                            x: "year",
                            y: "indexClamped",
                            stroke: "#ccc",
                            strokeWidth: 1.5,
                            opacity: 0.6
                        })
                    ),

                    // Arrow at the top of any clamped line
                    allArrowPoints.length > 0 ? Plot.text(allArrowPoints, {
                        x: "year",
                        y: () => yMax,
                        text: () => "^",
                        fontSize: 20,
                        fontWeight: "bold",
                        fill: d => d.standard_station === station.standard_station ? "#045B4C" : "#bbb",
                        stroke: "white",
                        strokeWidth: 3,
                        dy: -2
                    }) : null,

                    // Tooltip on arrow points showing the true clipped value
                    allArrowPoints.length > 0 ? Plot.tip(allArrowPoints, Plot.pointer({
                        x: "year",
                        y: () => yMax,
                        title: d => `${d.standard_station.replaceAll("_", " ")} (off scale)\n${d.year}: ${d.index.toFixed(1)} avg live olys/shell`
                    })) : null,

                    // Comparison dots — clamped, but skip points that have an arrow
                    ...compLinesClamped.map(lineData =>
                        Plot.dot(lineData.filter(d => d.index <= yMax), {
                            x: "year",
                            y: "indexClamped",
                            fill: "#ccc",
                            stroke: "white",
                            strokeWidth: 2,
                            r: 4
                        })
                    ),

                        // Highlighted line — clamped
                        Plot.lineY(
                            stationData.map(d => ({...d, indexClamped: Math.min(d.index, yMax)})),
                            {
                                x: "year",
                                y: "indexClamped",
                                stroke: "#045B4C",
                                strokeWidth: 2.5
                            }
                        ),

                        // Highlighted dots — clamped, skip points that have an arrow
                        Plot.dot(
                            stationData
                                .map(d => ({...d, indexClamped: Math.min(d.index, yMax)}))
                                .filter(d => d.index <= yMax),
                            {
                                x: "year",
                                y: "indexClamped",
                                fill: "#045B4C",
                                stroke: "white",
                                strokeWidth: 2,
                                r: 4
                            }
                        ),

                        // Unified tooltip — highlighted station rows are duplicated first
                        // so Plot.pointer() snaps to them preferentially when close
                        Plot.tip(
                            [...stationData, ...compLines.flat()],
                            Plot.pointer({
                                x: "year",
                                y: "index",
                                title: d => d.standard_station === station.standard_station
                                    ? `★ ${d.standard_station.replaceAll("_", " ")}\n${d.year}: ${d.index.toFixed(1)} avg live olys/shell`
                                    : `${d.standard_station.replaceAll("_", " ")}\n${d.year}: ${d.index.toFixed(1)} avg live olys/shell`
                            })
                        )
                    ],
                    style: { fontFamily: "inherit", fontSize: "13px" }
                });

            chartWrapper.appendChild(chart);

            // Note about outliers being clipped if any exist above yMax
            const clippedCount = allIndexValues.filter(v => v > yMax).length;
            const avgNote = document.createElement("p");
            avgNote.style.margin = "8px 0 0 0";
            avgNote.innerHTML = `
                <span style="font-size:12px; color:#777;">
                    ${clippedCount > 0 ? ` &nbsp;·&nbsp; ${clippedCount} outlier value${clippedCount > 1 ? "s" : ""} clipped from view` : ""}
                </span>`;
            chartWrapper.appendChild(avgNote);

        } else {
            const noData = document.createElement("p");
            noData.textContent = stationData.length === 1
                ? `Only one year of data available (${stationData[0].year}: ${stationData[0].index.toFixed(1)} live olys/shell).`
                : "No recruitment data recorded for this station.";
            Object.assign(noData.style, { fontSize: "13px", color: "#999", fontStyle: "italic", margin: "0" });
            chartWrapper.appendChild(noData);
        }
    }

    // Render on first load
    renderChart();

    // Assemble and show
    detailContainer.appendChild(buttonBar);
    detailContainer.appendChild(scrollBody);


} // END recruitment detail panel function


// ===================================================
// ===================================================
// RECRUITMENT MAP LAYER MANAGER
//
// Two display modes for the recruitment tab:
//
//   GROUPED mode (zoom < 10):
//     One circle per waterbody, colored by the
//     average index of all its stations for that year.
//     Clicking or zooming in expands to individual stations.
//
//   INDIVIDUAL mode (zoom >= 10 or after click):
//     One circle per station, same color scale.
//     Zooming back out returns to grouped mode.
//
// The year slider calls updateYear() in either mode.
// ===================================================
// ===================================================
function createRecruitmentLayerManager(recruitData, recruitLayer, map, onStationClick) {

    // -----------------------------------------------
    // Group data by year
    // byYear[2015] = [ ...all rows for 2015... ]
    // -----------------------------------------------
    const byYear = {};
    recruitData.forEach(row => {
        if (!row.year) return;
        if (!byYear[row.year]) byYear[row.year] = [];
        byYear[row.year].push(row);
    });

    // Sorted list of all unique years
    const years = Object.keys(byYear).map(Number).sort((a, b) => a - b);

    // Build deduplicated station lookup: stationName -> { lat, lng }
    const stationInfo = {};
    const seen = new Set();
    recruitData.forEach(row => {
        if (seen.has(row.standard_station)) return;
        if (!row.latitude || !row.longitude ||
            row.latitude === "NA" || row.longitude === "NA" ||
            isNaN(parseFloat(row.latitude))) return;
        seen.add(row.standard_station);
        stationInfo[row.standard_station] = {
            lat: parseFloat(row.latitude),
            lng: parseFloat(row.longitude)
        };
    });

    
    // -----------------------------------------------
    // Store the markers
    // -----------------------------------------------
    const individualMarkers  = {};  // station name - L.circleMarker

    // Track which mode we're in
    let currentYear = years[years.length - 1];  // start at latest year

    // -----------------------------------------------
    // HELPER: build yearData lookup for a given year
    // -----------------------------------------------
    function getYearData(year) {
        const yearData = {};
        (byYear[year] || []).forEach(row => {
            yearData[row.standard_station] = row;
        });
        return yearData;
    }

    // -----------------------------------------------
    // Build all markers once
    // Individual markers start hidden, waterbody
    // markers start visible (grouped is default).
    // -----------------------------------------------
    function init() {

        // --- Build individual station markers ---
        Object.entries(stationInfo).forEach(([stationName, info]) => {
            // Find a full row for this station to pass to onStationClick
            const stationRow = recruitData.find(d => d.standard_station === stationName);

            const marker = L.circleMarker([info.lat, info.lng], {
                radius: 7,
                fillColor: "#e0e0e0",
                color: "#999",
                weight: 1.5,
                opacity: 1,
                fillOpacity: 0.5
            });

            marker.bindTooltip(`
                <div style="padding:10px 12px; min-width:160px;">
                    <p style="font-size:13px; font-weight:600; color:#222;
                        margin:0 0 4px 0; text-align:center;">
                        ${stationName.replaceAll("_", " ")}
                    </p>
                    <p style="font-size:11px; color:#888; text-align:center;
                        margin:0; text-transform:uppercase; letter-spacing:0.4px;">
                        Recruitment Station
                    </p>
                </div>
            `, {
                direction: "top",
                permanent: false,
                className: "custom-tooltip"
            });

            marker.on("click", () => onStationClick(stationRow));
            marker.on("mouseover", () => {
                if (marker.getElement()) marker.getElement().style.cursor = "pointer";
            });

            // Start hidden (grouped mode is default)
            // (don't add to recruitLayer yet)
            marker.addTo(recruitLayer);
            individualMarkers[stationName] = marker;        
        });


        // Apply the latest year's data immediately
        updateYear(currentYear);
            
    }

    // -----------------------------------------------
    // UPDATE YEAR
    // Re-styles whichever set of markers is currently
    // visible for the newly selected year.
    // -----------------------------------------------
    function updateYear(year) {
        currentYear = year;
        const yearData = getYearData(year);

        Object.entries(individualMarkers).forEach(([stationName, marker]) => {
            const row = yearData[stationName];
            const value = (row && row.index !== null && !isNaN(row.index)) ? row.index : null;

            marker.setRadius(spatToRadius(value));
            marker.setStyle({
                fillColor: spatToColor(value),
                color: value !== null ? "white" : "#999",
                weight: 1.5,
                opacity: 1,
                fillOpacity: value !== null ? 0.9 : 0.5
            });

            marker.setTooltipContent(
                value !== null ? `
                    <div style="padding:10px 12px; min-width:180px;">
                        <p style="font-size:13px; font-weight:600; color:#222;
                            margin:0 0 6px 0; text-align:center;">
                            ${stationName.replaceAll("_", " ")}
                        </p>
                        <div style="height:1px; background:#e8e8e8; margin:0 0 6px 0;"></div>
                        <div style="display:flex; justify-content:space-between;
                            font-size:12px; color:#555;">
                            <span style="color:#045B4C; font-weight:600;">${year}</span>
                            <span>${value.toFixed(1)} avg live olys/shell</span>
                        </div>
                    </div>
                ` : `
                    <div style="padding:10px 12px; min-width:160px;">
                        <p style="font-size:13px; font-weight:600; color:#222;
                            margin:0 0 4px 0; text-align:center;">
                            ${stationName.replaceAll("_", " ")}
                        </p>
                        <p style="font-size:12px; color:#aaa; text-align:center; margin:0;">
                            No data for ${year}
                        </p>
                    </div>
                `
            );
        });
    }
    // Show
    return { years, updateYear, init };

} // END Recruitment layer manager function

// ===================================================
// ===================================================
// MAP LEGEND BUILDER: RECRUITMENT
//
// Shows a color ramp
//
// Arguments:
//   map: Leaflet map instance
//   maxValue: global max spat value (for scale labels)
// ===================================================
// ===================================================
function addRecruitmentLegend(map, maxValue) {
    const legend = L.control({ position: "topright" });

    legend.onAdd = function() {
        const div = L.DomUtil.create("div", "recruit-legend");

        div.innerHTML = `
    <div style="background:white; padding:14px; border-radius:8px;
        box-shadow:0 2px 8px rgba(0,0,0,0.15); font-size:12px; min-width:170px;">

        <div style="font-weight:700; color:#045B4C; font-size:11px;
            text-transform:uppercase; letter-spacing:0.5px; margin-bottom:10px;">
            Avg Live Olys / Shell
        </div>

        ${[
            { color: "#c8c8c8", label: "No data" },
            { color: "#ffffcc", label: "0" },
            { color: "#ffeda0", label: "0 – 1" },
            { color: "#fed976", label: "1 – 2" },
            { color: "#feb24c", label: "2 – 3" },
            { color: "#fd8d3c", label: "3 – 5" },
            { color: "#f03b20", label: "5 – 10" },
            { color: "#bd0026", label: "10 – 20" },
            { color: "#67000d", label: "≥ 20" },
        ].map(bin => `
            <div style="display:flex; align-items:center; gap:8px; margin-bottom:5px;">
                <div style="width:14px; height:14px; border-radius:50%;
                    background:${bin.color}; border:1.5px solid rgba(0,0,0,0.15);
                    flex-shrink:0;"></div>
                <span style="color:#555;">${bin.label}</span>
            </div>
        `).join("")}
    </div>
`;
        return div;
    };

    legend.addTo(map);
    return legend;  // return so we can .remove() it when switching tabs
} // END recruitment legend builder



// ===================================================
// ===================================================
// FILTER PANEL
// Tab switcher at top for enhancement or recruitment
// 
// In enhancement tab:
//      Filter by restoration action
//      Drop down menu to jump to sites with written stories
// In recruitment tab:
//      Year slider
// ===================================================
// ===================================================
function createFilterPanel(enhancementLayer, recruitmentLayer, map, enhData, recruitData, recruitLayerManager, enhancementLegend, onTabSwitch) {
    // Track currently open enhancement tooltip 
    // so we can close it before opening a new one
    let currentOpenMarker = null;

    // Track the active recruitment legend so we can remove it on tab switch
    let activeRecruitLegend = null;

    // Which tab is currently shown: "enhancement" or "recruitment"
    let currentTab = "enhancement";

    // -----------------------------------------------
    // Outer panel div
    // -----------------------------------------------
    const panel = document.createElement("div");
    panel.style.padding = "0";

    // -----------------------------------------------
    // TAB SWITCHER
    // Two pill buttons at the top of the filter panel.
    // The active tab has a filled green style.
    // -----------------------------------------------
    const tabBar = document.createElement("div");
    Object.assign(tabBar.style, {
        display: "flex",
        flexWrap: "wrap",
        gap: "8px",
        marginBottom: "12px",
        marginTop: "12px"
    });

    // Helper: creates one tab button
    function makeTabBtn(label, tabId) {
        const btn = document.createElement("button");
        btn.textContent = label;
        btn.dataset.tab = tabId;
        Object.assign(btn.style, {
            flex: "1",
            padding: "9px 10px",
            border: "2px solid #045B4C",
            borderRadius: "6px",
            fontSize: "12px",
            fontWeight: "600",
            cursor: "pointer",
            transition: "all 0.2s ease",
            textTransform: "uppercase",
            letterSpacing: "0.4px",
            // Enhancement starts active
            backgroundColor: tabId === "enhancement" ? "#045B4C" : "white",
            color: tabId === "enhancement" ? "white" : "#045B4C"
        });
        return btn;
    }

    const enhTab   = makeTabBtn("Enhancement", "enhancement");
    const recruitTab = makeTabBtn("Recruitment", "recruitment");
    tabBar.appendChild(enhTab);
    tabBar.appendChild(recruitTab);
    const tabHeader = document.createElement("div");
    tabHeader.style.cssText = "font-size:12px; font-weight:600; color:#045B4C; margin-bottom:8px; text-transform:uppercase; letter-spacing:0.5px;";
    tabHeader.textContent = "Choose Map View";
    panel.appendChild(tabHeader);

    panel.appendChild(tabBar);

    const tabSubtext = document.createElement("div");
    tabSubtext.style.cssText = "font-size:11px; color:#666; font-style:italic; line-height:1.6; margin-bottom:24px;";
    tabSubtext.textContent = "Enhancement shows restoration sites. Recruitment shows long-term monitoring stations tracking annual oyster settlement.";
    panel.appendChild(tabSubtext);


    // -----------------------------------------------
    // ENHANCEMENT TAB CONTENT
    // Wrapped in a div so we can show/hide with display
    // -----------------------------------------------
    const enhContent = document.createElement("div");

    // Write all static HTML for filter panel
    enhContent.innerHTML = `
        <div style="padding: 0;">

            <!-- Decorative horizontal divider line -->
            <div style="height: 1px; background: linear-gradient(to right, transparent, #ddd, transparent); margin: 24px 0;"></div>

            <!-- Story Site Dropdown (static HTML here, dynamic content added below) -->
            <div style="margin-bottom: 24px;">
                <label style="display: block; font-size: 13px; font-weight: 600; color: #045B4C;
                    margin-bottom: 8px; text-transform: uppercase; letter-spacing: 0.5px;">Read a Story</label>
                <!-- Empty selector, options are added by the JavaScript below -->
                <select id="site-selector" style="
                    width: 100%; padding: 10px 12px; border: 2px solid #e0e0e0; border-radius: 6px;
                    font-size: 14px; background: white; cursor: pointer;
                    transition: all 0.2s ease; color: #333;">
                    <option value="">Select a site...</option>
                </select>
                <div style="font-size: 11px; color: #666; margin-top: 6px; font-style: italic;">
                    Zoom to a site and view its story</div>
            </div>

            <!-- Decorative horizontal divider line -->
            <div style="height: 1px; background: linear-gradient(to right, transparent, #ddd, transparent); margin: 24px 0;"></div>


            <!-- Enhancement Type filter: oblong toggle buttons -->
            <div style="margin-bottom: 20px;">
                <label style="display: block; font-size: 13px; font-weight: 600; color: #045B4C;
                    margin-bottom: 8px; text-transform: uppercase; letter-spacing: 0.5px;">
                    Filter by Enhancement Type</label>
                <div style="display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 8px;">
                    <!-- Each button has a "data-type" attribute -->
                    <button class="type-toggle-btn" data-type="bulk shell" style="
                        padding: 8px 16px; border: 2px solid #045B4C; border-radius: 20px;
                        background: #045B4C; color: white; font-size: 13px; font-weight: 500;
                        cursor: pointer; transition: all 0.2s ease; white-space: nowrap;">Bulk Shell</button>
                    <button class="type-toggle-btn" data-type="seeded cultch" style="
                        padding: 8px 16px; border: 2px solid #045B4C; border-radius: 20px;
                        background: #045B4C; color: white; font-size: 13px; font-weight: 500;
                        cursor: pointer; transition: all 0.2s ease; white-space: nowrap;">Seeded Cultch</button>
                    <button class="type-toggle-btn" data-type="singles" style="
                        padding: 8px 16px; border: 2px solid #045B4C; border-radius: 20px;
                        background: #045B4C; color: white; font-size: 13px; font-weight: 500;
                        cursor: pointer; transition: all 0.2s ease; white-space: nowrap;">Singles</button>
                </div>
                <div style="font-size: 11px; color: #666; margin-top: 6px; font-style: italic;">
                    Select which enhancement methods are displayed</div>
            </div>
        </div>
    `; // END HTML for filter panel

    // -----------------------------------------------
    // RECRUITMENT TAB CONTENT
    // Year slider + explanatory text. Hidden by default.
    // -----------------------------------------------
    const recruitContent = document.createElement("div");
    recruitContent.style.display = "none";

    // Waterbody jump dropdown (only shows waterbodies that have coordinates)
    const wbDropdownWrapper = document.createElement("div");
    wbDropdownWrapper.innerHTML = `
        <label style="display:block; font-size:13px; font-weight:600; color:#045B4C;
            margin-bottom:8px; text-transform:uppercase; letter-spacing:0.5px;">Jump to Waterbody</label>
        <select id="waterbody-selector" style="width:100%; padding:10px 12px; border:2px solid #e0e0e0;
            border-radius:6px; font-size:14px; background:white; cursor:pointer; color:#333;">
            <option value="">Select a waterbody...</option>
        </select>
        <div style="font-size:11px; color:#666; margin-top:6px; font-style:italic;">
            Zoom to a waterbody and view its stations</div>
    `;

    // Populate the dropdown from the recruitment data
    const uniqueWaterbodies = [...new Set(
        recruitData
            .filter(d => d.waterbody && d.latitude && d.latitude !== "NA")
            .map(d => d.waterbody)
    )].sort();

    const wbSelector = wbDropdownWrapper.querySelector("#waterbody-selector");
    uniqueWaterbodies.forEach(wb => {
        const option = document.createElement("option");
        option.value = wb;
        option.textContent = wb;
        wbSelector.appendChild(option);
    });

    // When a waterbody is selected, zoom the map to fit its stations
    wbSelector.addEventListener("change", (e) => {
        const wb = e.target.value;
        if (!wb) return;

        const stations = recruitData.filter(d =>
            d.waterbody === wb &&
            d.latitude && d.latitude !== "NA" &&
            !isNaN(parseFloat(d.latitude))
        );

        if (stations.length === 0) return;

        const lats = stations.map(d => parseFloat(d.latitude));
        const lngs = stations.map(d => parseFloat(d.longitude));

        map.fitBounds(
            L.latLngBounds(
                [Math.min(...lats) - 0.02, Math.min(...lngs) - 0.02],
                [Math.max(...lats) + 0.02, Math.max(...lngs) + 0.02]
            ),
            { animate: true, padding: [30, 30] }
        );
    });

    // Reset dropdown when user zooms back out
    map.on("zoomend", () => {
        if (map.getZoom() < 10) wbSelector.value = "";
    });

    // Focus/blur styling to match the enhancement dropdown
    wbSelector.addEventListener("focus", () => {
        wbSelector.style.borderColor = "#045B4C";
        wbSelector.style.boxShadow = "0 0 0 3px rgba(4,91,76,0.1)";
    });
    wbSelector.addEventListener("blur", () => {
        wbSelector.style.borderColor = "#e0e0e0";
        wbSelector.style.boxShadow = "none";
    });

    // Year slider
    const sliderContainer = document.createElement("div");

    if (recruitLayerManager && recruitLayerManager.years.length > 0) {
        const years = recruitLayerManager.years;
        const latestYear = years[years.length - 1];

        const slider = buildYearSlider(years, latestYear, (year) => {
            recruitLayerManager.updateYear(year);
        });
        sliderContainer.appendChild(slider);
        recruitLayerManager.updateYear(latestYear);
    }

    const sliderNote = document.createElement("p");
    sliderNote.textContent = "Drag the slider to explore recruitment across different years. Circle size and color reflect the average number of spat settled per shell at each station.";
    Object.assign(sliderNote.style, {
        fontSize: "11px",
        color: "#666",
        lineHeight: "1.5",
        margin: "4px 0 0 0",
        fontStyle: "italic"
    });
    sliderContainer.appendChild(sliderNote);

    // Note about clicking stations
    const clickHint = document.createElement("div");
    clickHint.innerHTML = `
        <div style="font-size:12px; color:#666; font-style:italic;
            padding:10px 12px; background:#f8f9fa; border-radius:6px;">
            ▶ Click any station to view its recruitment history
        </div>
    `;

    // -----------------------------------------------
    // Append all recruitment sections with dividers
    // -----------------------------------------------

    const divider1 = document.createElement("div");
    divider1.style.cssText = "height:1px; background:linear-gradient(to right, transparent, #ddd, transparent); margin:24px 0;";
    recruitContent.appendChild(divider1);

    recruitContent.appendChild(wbDropdownWrapper);

    const divider2 = document.createElement("div");
    divider2.style.cssText = "height:1px; background:linear-gradient(to right, transparent, #ddd, transparent); margin:24px 0;";
    recruitContent.appendChild(divider2);

    recruitContent.appendChild(sliderContainer);

    const divider3 = document.createElement("div");
    divider3.style.cssText = "height:1px; background:linear-gradient(to right, transparent, #ddd, transparent); margin:24px 0;";
    recruitContent.appendChild(divider3);

    recruitContent.appendChild(clickHint);

    // -----------------------------------------------
    // Add both content sections to the panel
    // -----------------------------------------------
    panel.appendChild(enhContent);
    panel.appendChild(recruitContent);

    // -----------------------------------------------
    // TAB SWITCHING LOGIC
    // When a tab button is clicked:
    //   - Update button styles (active vs inactive)
    //   - Show/hide the right content section
    //   - Add/remove the appropriate map layers
    //   - Swap the legend
    //   - Call onTabSwitch() so oysterMap() can respond
    // -----------------------------------------------
    function switchTab(tabId) {
        currentTab = tabId;

        // Update tab button styles
        [enhTab, recruitTab].forEach(btn => {
            const isActive = btn.dataset.tab === tabId;
            btn.style.backgroundColor = isActive ? "#045B4C" : "white";
            btn.style.color = isActive ? "white" : "#045B4C";
        });

        if (tabId === "enhancement") {
            // Show enhancement content, hide recruitment content
            enhContent.style.display = "block";
            recruitContent.style.display = "none";

            // Show enhancement layer, hide recruitment layer
            enhancementLayer.addTo(map);
            recruitmentLayer.remove();

            // Restore the original enhancement legend, remove recruitment legend
            if (activeRecruitLegend) {
                activeRecruitLegend.remove();
                activeRecruitLegend = null;
            }
            if (enhancementLegend) enhancementLegend.addTo(map);

        } else {
            // Show recruitment content, hide enhancement content
            enhContent.style.display = "none";
            recruitContent.style.display = "block";

            // Show recruitment layer, hide enhancement layer
            recruitmentLayer.addTo(map);
            enhancementLayer.remove();

            // Remove enhancement legend, add recruitment legend
            if (enhancementLegend) enhancementLegend.remove();
            if (!activeRecruitLegend) {
                activeRecruitLegend = addRecruitmentLegend(map, recruitLayerManager.globalMax);
            }
        }

        // Notify oysterMap() of the switch (e.g. to close any open detail panel)
        if (onTabSwitch) onTabSwitch(tabId);
    }

    // Wire up click events on both tab buttons
    enhTab.addEventListener("click",    () => switchTab("enhancement"));
    recruitTab.addEventListener("click", () => switchTab("recruitment"));

    // -----------------------------------------------
    // ENHANCEMENT TAB: wire up existing interactivity
    // (site selector, layer toggles, type filter buttons)
    // -----------------------------------------------

    // Add options to the site selector dropdown dynamically 
    // (so as we add sites, they will add here too!)
    // Find the select element from memory
    const siteSelector = panel.querySelector('#site-selector');

    // Build the list of sites to show in the dropdown
    // Only include sites tha thave valid coordinates and are in story_sites
    const uniqueSites = [...new Set( // Wrapping in Set will remove duplicates, [... ] spreads it to an array
        enhData
            .filter(site =>
                // Keep only rows where ALL of these are trure
                site.latitude && site.longitude &&   // latitude and longitude exist
                site.latitude !== 'NA' && site.longitude !== 'NA' &&   // and aren't the string "NA"
                !isNaN(parseFloat(site.latitude)) && !isNaN(parseFloat(site.longitude)) &&   // and are actual numbers
                story_sites.has(site.site_name)   // and the site has a story panel
            )
            .map(site => site.site_name) // Only keep the site name

    )].sort(); // Alphabetize 

    // For each site name, create an option element
    uniqueSites.forEach(siteName => {
        const option = document.createElement('option');
        option.value = siteName;
        option.textContent = siteName;
        siteSelector.appendChild(option);
    });

    // Listen for when the user selects a site from the dropdown
    siteSelector.addEventListener('change', (e) => {
        const selectedSite = e.target.value;  // the value of the chosen option

        // Only proceed if something was selected AND that site has a marker on the map
        // window.markersBySite is the global object storing all markers by site name
        if (selectedSite && window.markersBySite[selectedSite]) {
            const marker = window.markersBySite[selectedSite];
            const latLng = marker.getLatLng();  // get the marker's coords

            // If a tooltip is already open, close it before opening a new one!!!
            if (currentOpenMarker) currentOpenMarker.closeTooltip();

            // Recenter the map on this site. animate:true makes it look nice!
            map.setView(latLng, 12, { animate: true, duration: 0.5 });

            // Wait 600ms for the zoom animation to finish, then open the tooltip
            // Otherwise things were getting wonky
            setTimeout(() => {
                marker.openTooltip();
                currentOpenMarker = marker;  // remember this as the now-open marker
            }, 600);
        }
    });

    // When the user zooms out past zoom level 11,
    // reset the dropdown back to the placeholder "Select a site..." option
    // Keeps the dropdown in sync with what the map is showing!
    map.on('zoomend', () => {
        if (map.getZoom() < 11) siteSelector.value = '';
    });

    // -----------------------------------------------
    // Enhancement type toggle buttons
    // -----------------------------------------------

    // Start with all 3 enhancement buttons as active
    const activeTypes = new Set(['bulk shell', 'seeded cultch', 'singles']);

    // Take the enhancement_actions column from the CSV and split into an array of strings
    // eg. "bulk shell, seeded cultch" to ["bulk shell", "seeded cultch"]
    // .map(t => t.length >0) removes whitespace
    // .filter(t => t.length > 0) removes any empty strings
    function normalizeType(typeString) {
        if (!typeString) return [];  // if the value is empty, return empty array
        return typeString.split(',').map(t => t.trim().toLowerCase()).filter(t => t.length > 0);
    }

    // Loop through all enhancement sites and show/hide markers
    // based on if it is selected or not
    function filterEnhancementMarkers() {
        enhData.forEach(site => {
            const marker = window.markersBySite[site.site_name];
            if (marker) {
                // Get this sites enhancement types
                const siteTypes = normalizeType(site.enhancement_actions);

                // .some() returns true if at least one item in an array passes test
                const shouldShow = siteTypes.some(type => activeTypes.has(type));

                if (shouldShow) {
                    // hasLayer() checks if the marker is already on the layer —
                    // we only add it if it's not already there, to avoid duplicates
                    if (!enhancementLayer.hasLayer(marker)) enhancementLayer.addLayer(marker);
                } else {
                    if (enhancementLayer.hasLayer(marker)) enhancementLayer.removeLayer(marker);
                }
            }
        });
    }

    // Find all three toggle buttons
    const typeToggleBtns = panel.querySelectorAll('.type-toggle-btn');

    typeToggleBtns.forEach(btn => {
        
        // When a button is clicked toggle it in and out of the activeTypes
        btn.addEventListener('click', () => {
            const type = btn.getAttribute('data-type');

            if (activeTypes.has(type)) {
                // Type was active: deactivate it
                activeTypes.delete(type);
                // Style button as "off": white background, green text
                btn.style.background = 'white';
                btn.style.color = '#045B4C';
            } else {
                // Type was inactive: activate it
                activeTypes.add(type);
                // Style button as "on": green background, white text
                btn.style.background = '#045B4C';
                btn.style.color = 'white';
            }

            // Re-run the marker filter with the updated activeTypes set
            filterEnhancementMarkers();
        });

        // Hover effect: slightly different shade depending on the active state
        btn.addEventListener('mouseenter', () => {
        if (!activeTypes.has(btn.getAttribute('data-type'))) {
            // Inactive button hover: light green tint
            btn.style.background = '#e8f4f2';
            btn.style.color = '#045B4C';
        } else {
            // Active button hover: slightly darker green
            btn.style.background = '#034a3e';
        }
        });

        // When mouse leaves, restore the correct active/inactive style
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

    // -----------------------------------------------
    // Dropdown focus/blur styling
    // Adds a green border glow when the dropdown is clicked on,
    // restores the default border when click leaves
    // -----------------------------------------------
    siteSelector.addEventListener('focus', () => {
        siteSelector.style.borderColor = '#045B4C';
        siteSelector.style.boxShadow = '0 0 0 3px rgba(4, 91, 76, 0.1)';
    });
    siteSelector.addEventListener('blur', () => {
        siteSelector.style.borderColor = '#e0e0e0';
        siteSelector.style.boxShadow = 'none';
    });

    // Return the fully built panel element
    return panel;
} // END FILTER PANEL FUNCTION

// ===================================================
// ===================================================
// MAIN MAP FUNCTION
// This is really the core function that builds everything:
// The Leaflet map, all markers, the detail panel that
// pops open when you click on a story site, and the 
// map reset when you close the panel
//
// Arguments:
//  - enhData: Enhancement sites metadata CSV
//  - recruitData: Recruitment data CSV
//  - timelineData: Enhancement timeline CSV
//  - {width}: the current container width which dynamically comes from resize()
// ===================================================
// ===================================================
function oysterMap(enhData, recruitData, timelineData, {width} = {}) {
    
    // -----------------------------------------------
    // BUILD THE CONTAINER DIVS
    // Three nested divs:
    //   - mainContainer: the outer wrapper (holds map + detail side by side)
    //      - mapContainer: the Leaflet map lives here
    //      - detailContainer: the site story panel (hidden until a site is clicked)
    // -----------------------------------------------

    // The outermost div
    // Width comes from resize() which passes the current pade width
    // so the map will fill the available space
    const mainContainer = document.createElement("div");
    Object.assign(mainContainer.style, {
        width: `${width}px`,
        height: "90vh", // 90% of the browser window for height
        minHeight: "600px" // never shrink below 600px even on small screens
    });

    // The div for the Leaflet map
    // Starts at full width but shrinks to 40% when a story panel opens
    const mapContainer = document.createElement("div");
    Object.assign(mapContainer.style, {
        width: "100%",
        height: "100%",
        borderRadius: "8px",
        transition: "all 0.25s ease-in-out"  // smooth animation when width changes
    });

    // The story panel div, starts hidden (display: "none")
    // When a story site icon is clicked it displays ("flex")
    // There is a frozen button bar at the top and the rest scrolls vertically
    const detailContainer = document.createElement("div");
    Object.assign(detailContainer.style, {
        display: "none",   // invisible until showDetail() is called
        width: "80%",   // takes 60% of mainContainer when visible
        height: "100%",
        backgroundColor: "white",
        borderRadius: "8px",
        transition: "all 1s ease-in-out",
        opacity: "0",   // starts transparent, fades in
        overflowY: "hidden",   // the container itself does NOT scroll only the scrollBody inside it does
        overflowX: "hidden",   // no horizontal scrolling
        boxSizing: "border-box",   // padding is included in the width/height calculation
        flexDirection: "column"   // when display becomes "flex", content stacks vertically
    });

    // Add both child divs into the main container 
    // appendChild() places an element inside another
    mainContainer.appendChild(mapContainer);
    mainContainer.appendChild(detailContainer);


    // -----------------------------------------------
    // INITIALISE THE LEAFLET MAP
    // L is the Leaflet library imported at the top of the code
    // L.map() takes a DOM element and an options object
    // center and zoom are also constants defined at the top!
    // -----------------------------------------------
    const map = L.map(mapContainer, { center, zoom });

    // Store the map container so the filter panel can access it later
    // _map means we are making it an internal property of the main container
    mainContainer._map = map;

    // Add the basemap layer
    // Using map imagery from CartoDB
    L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
        attribution: '© OpenStreetMap © CartoDB', // Attribution required for free use
        maxZoom: 15
    }).addTo(map);


    // -----------------------------------------------
    // CREATE LAYER GROUPS
    // Layer groups let us show/hide all markers of a type at once
    // Both start added to the map by default
    // The filter panel checkboxes call .addTo(map) or .remove() on these layers !!
    // -----------------------------------------------
    const recruitmentLayer = L.layerGroup();
    const enhancementLayer = L.layerGroup().addTo(map);

    // Store markers by site name globally so they can be accessed by the filter panel
    window.markersBySite = {};

    // ===================================================
    // SHOW DETAIL PANEL
    // Called when the user clicks a story site marker.
    // Rearranges the layout so the map shrinks to 40% and
    // the story panel fills the remaining 60%.
    // ===================================================
    function showDetail(site) {
        // Record which site is currently open globally so other 
        // parts of the code can check which site is selected
        window.selectedSite = site.site_name;

        // Switch mainContainer from "block" layout (map full width)
        // to "flex" layout (two inner panels side by side)
        mainContainer.style.display = "flex";
        mainContainer.style.gap = "10px";   // small gap between map and story panel

        // Shrink the map to 40% width
        mapContainer.style.width = "30%";
        mapContainer.style.flexShrink = "0";   // don't let flex squish it any further

        // Show the detail panel as a flex column
        detailContainer.style.display = "flex";

        // Fade the panel in
        // 10ms delay makes sure display:flex is initiated before we try and animate
        setTimeout(() => detailContainer.style.opacity = "1", 10);

        // Tell leaflet the map container changed size, then zoom to the site
        setTimeout(() => {
            map.invalidateSize();  // recalc map dimensions after resize
            map.setView(
                [site.latitude, site.longitude + 0.02],  // Recenter the map here
                13,  // At this zoom level
                { animate: false }  // Jump instantly without an animation
            );
        }, 50);

        // Clear any previously shown site content before building the new one
        detailContainer.innerHTML = "";

        // -----------------------------------------------
        // Zone 1: Back Button bar
        // Sits at the top of the detail panel & never scrolls out of view
        // flexShrink:"0" means flex will never compress this div
        // even if the content below needs more space! 
        // Let the user get out of there easy
        // -----------------------------------------------
        const buttonBar = document.createElement("div");
        Object.assign(buttonBar.style, {
            flexShrink: "0",
            padding: "16px 20px",
            borderBottom: "1px solid #e0e0e0",
            backgroundColor: "white",
            borderRadius: "8px 8px 0 0",  // only round the top two corners, the bottom edge butts against scrollBody
            zIndex: "10", // sit above scrolled content if it creeps up
            display: "flex", // side by side layout for title
            alignItems: "center",
            justifyContent: "space-between"
        });

        // Build the back button to return to the full map view, closing detail panel
        const backButton = document.createElement("button");
        backButton.textContent = "← Back to Map";
        Object.assign(backButton.style, {
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

        // Hover effect!! swap background and text color when mouse goes over button
        // onmouseenter/onmouseleave are shorthand for addEventListener
        backButton.onmouseenter = () => {
            backButton.style.backgroundColor = "#045B4C";
            backButton.style.color = "white";
        };
        backButton.onmouseleave = () => {
            backButton.style.backgroundColor = "white";
            backButton.style.color = "#045B4C";
        };

        // Wire up the click to call resetView() (defined below)
        backButton.onclick = resetView;

        // Place the button inside the button bar div that doesn't scroll away
        buttonBar.appendChild(backButton);

        const siteTitle = document.createElement("h2");
        siteTitle.textContent = site.site_name;
        Object.assign(siteTitle.style, {
            margin: "0",
            fontSize: "28px",
            fontWeight: "700",
            color: "#045B4C",
            letterSpacing: "0.5px"
        });

        buttonBar.appendChild(siteTitle);

        // -----------------------------------------------
        // Zone 2: Scroll body
        // Fills all remaining height below the button bar
        // flexGrow:"1" means "take up all leftover space"
        // This is the story and graphs that you can scroll through
        // -----------------------------------------------
        const scrollBody = document.createElement("div");
        Object.assign(scrollBody.style, {
            flexGrow: "1",  // expand to fill remaining height after buttonBar
            overflowY: "auto",   // show scrollbar only when content is taller than the div
            overflowX: "hidden",    // no horizontal scrolling
            padding: "20px",
            boxSizing: "border-box"
        });

        // Add both zones into the detail container.
        // Order matters: buttonBar first = top, scrollBody second = below it.
        detailContainer.appendChild(buttonBar);
        detailContainer.appendChild(scrollBody);

        // Grab the site's content from the site panel builder and
        // place it in the scrollable area
        const sitePanel = buildSitePanel(site.site_name);
        scrollBody.appendChild(sitePanel);
    }

    // ===================================================
    // RESET VIEW
    // Called by the back button, essentially reverses everything 
    // showDetail() did:
    //      - fades out the panel
    //      - restores the map to full width
    //      - and resets the zoom to the default overview
    // ===================================================  
    function resetView() {

        // Clear the selected site record
        window.selectedSite = null;

        // Start the fade oout
        detailContainer.style.opacity = "0";

        // Wait a sec for the fade to finish before restructering layot
        setTimeout(() => {
            mainContainer.style.display = "block";  // reset to a single column so the map is full width
            Object.assign(mapContainer.style, {
                width: "100%",
                height: "100%"
            });
            detailContainer.style.display = "none"; // hide the detail panel

            // Wait another sec for the layout shift to settle and
            // then tell Leaflet to recalculate size and set view
            setTimeout(() => {
                map.invalidateSize();
                map.setView(center, zoom, { animate : false });
            }, 250);
        }, 250);
    }


    // ===================================================
    // Build the recruitment circle marker layer.
    // createRecruitmentLayerManager() handles marker creation,
    // styling, and click actions
    // ===================================================
    const recruitLayerManager = createRecruitmentLayerManager(
        recruitData,
        recruitmentLayer,
        map,
        (station) => showRecruitmentDetail(
            station,
            recruitData,
            detailContainer,
            map,
            mainContainer,
            mapContainer,
            resetView
        )
    );
    recruitLayerManager.init();


    // ===================================================
    // ADD ENHANCEMENT MARKERS
    // Story sites get seperate styling
    // Story sites get a click handler that opens the detail panel!!
    // ===================================================
    enhData.forEach(site => {
        // Skip this row if coordinates are missing or invalid
        if(!site.latitude || !site.longitude ||
            site.latitude === 'NA' || site.longitude === 'NA' ||
            isNaN(parseFloat(site.latitude)) || isNaN(parseFloat(site.longitude))) return;

        // story_sites is the Set defined at the top of the file
        // .has() checks if site_name is in that Set
        const isStorySite = story_sites.has(site.site_name);

        // Pick different color for story sites
        // This is called a ternary: condition ? value_if_true : value_if_false
        const icon = isStorySite ? enhancementStoryIcon : enhancementIcon;

        const photoUrl = tooltipPhotos[site.site_name];

        // Create the marker with the right icon
        // By using an arrow function to build the tooltip, we allow
        // Leaflet to build it only when the tooltip is about to open
        // and not at the loading when the marker is created
        const marker = L.marker(
            [site.latitude, site.longitude],
            { icon: icon }
        )
        .bindTooltip(
            () => buildTooltipHTML(site, timelineData, isStorySite, photoUrl),
            {
                direction: 'auto',
                permanent: false,
                className: 'custom-tooltip'
            }
        )
        .addTo(enhancementLayer);

        // Only story sites get a click handler and a pointer cursor
        // Non story sites are visible on the map and show the tooltip
        // but clicking doesn't do anything
        if (isStorySite) {

            // marker.on() is Leaflet's version of addEventListener
            marker.on("click", () => showDetail(site));

            // getElement() returns the HTML element for this marker so we
            // can get the CSS cursor style that we create
            marker.on("mouseover", () => {
                marker.getElement().style.cursor = "pointer";
            });
        }

        // Store marker reference for the site selector dropdown
        window.markersBySite[site.site_name] = marker;
    });


    // ===================================================
    // LEGEND
    // L.control() creates a Leaflet control
    // onAdd() is called by Leaflet when it's ready to place
    // the control; it must return a DOM element
    // ===================================================
    const legend = L.control({ position: 'topright' });  // Put it in the top right corner
    let enhancementLegend; // we'll store a reference so the filter panel can show/hide it

    legend.onAdd = function() {
        // L.DomUtil.create() is Leaflet's helper for creating DOM elements
        // First arg is tag name, second is CSS class
        const div = L.DomUtil.create('div', 'map-legend');

        div.innerHTML = `
            <div style="
                background: white; padding: 12px; border-radius: 8px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.15); font-size: 13px;">

                <!-- No story site row: plain blue circle -->
                <div style="display: flex; align-items: center; margin: 5px 0;">
                    <div style="
                        background-color: #4e79a7; width: 14px; height: 14px; border-radius: 50%;
                        border: 2px solid white; margin-right: 8px; flex-shrink: 0;"></div>
                    Enhancement Site
                </div>

                <!-- Enhancement Site with story -->
                <div style="display: flex; align-items: center; margin: 5px 0;">
                    <div style="
                        background-color: #EE934F; width: 14px; height: 14px; border-radius: 50%;
                        border: 2px solid white; margin-right: 8px; flex-shrink: 0;"></div>
                    Enhancement Story - Click to learn more
                </div>
        `;

        // return the element so leaflet can place it
        return div;
    };

    enhancementLegend = legend;
    legend.addTo(map);

    // Add scale bar
    L.control.scale({ imperial: true, metric: true }).addTo(map);

    // -----------------------------------------------
    // RESET VIEW BUTTON on map
    // Returns map to default center + zoom
    // -----------------------------------------------
    const resetBtn = L.control({ position: "topleft" });
    resetBtn.onAdd = function() {
        const btn = L.DomUtil.create("button", "leaflet-reset-btn");
        btn.title = "Reset zoom level";
        btn.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" 
            viewBox="0 0 24 24" fill="none" stroke="currentColor" 
            stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M3 3h6M3 3v6M21 3h-6M21 3v6M3 21h6M3 21v-6M21 21h-6M21 21v-6"/>
        </svg>`;
        Object.assign(btn.style, {
            background: "white",
            border: "2px solid rgba(0,0,0,0.2)",
            borderRadius: "4px",
            width: "32px",
            height: "32px",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#333",
            padding: "0"
        });
        btn.onclick = () => map.setView(center, zoom, { animate: true });
        // Prevent map clicks from firing when clicking button
        L.DomEvent.disableClickPropagation(btn);
        return btn;
    };
    resetBtn.addTo(map);

    // When the browser window is resized, tell Leaflet to
    // recalculate the map's pixel dimensions after 100ms
    // The delay prevents it running dozens of times during a drag resize!
    window.addEventListener('resize', () => setTimeout(() => map.invalidateSize(), 100));

    // Also invalidate once immediately on load, in case the map
    // renders before its container has fully settled to its final size
    // Fix weird loading
    setTimeout(() => map.invalidateSize(), 100);

    // Store the layer groups on the container so createFilterPanel()
    // can access them after the map is built
    mainContainer._enhancementLayer = enhancementLayer;
    mainContainer._recruitmentLayer = recruitmentLayer;
    mainContainer._recruitLayerManager = recruitLayerManager;
    mainContainer._enhancementLegend = enhancementLegend;
    mainContainer._resetView = resetView;  // expose so filter panel can call it from outside

    // Return the whole assembled container div
    return mainContainer;
} // END MAIN MAP FUNCTION


// ===================================================
// INSTANTIATE MAP
// Build once, place in a persistent div, use
// ResizeObserver to keep width in sync without
// ever rebuilding the map or touching its DOM.
// ===================================================

// Wait for the placeholder card to exist in the DOM
setTimeout(() => {
    const placeholder = document.querySelector('#map-card-placeholder');
    if (!placeholder) return;

    // Build the map once at the placeholder's actual current width
    const initialWidth = placeholder.offsetWidth || 800;
    const container = oysterMap(
        enh_sites_metadata,
        recruitment_data,
        timeline_data,
        { width: initialWidth }
    );
    window.currentMapInstance = container;

    // Place the map inside the placeholder card — it stays here forever
    placeholder.appendChild(container);

    // Build the filter panel once
    setTimeout(() => {
        const filterContainer = document.querySelector('#filter-container');
        if (filterContainer && container._enhancementLayer) {
            filterContainer.innerHTML = '';
            filterContainer.appendChild(
                createFilterPanel(
                    container._enhancementLayer,
                    container._recruitmentLayer,
                    container._map,
                    enh_sites_metadata,
                    recruitment_data,                   // full recruitment CSV
                    container._recruitLayerManager,  // layer manager with years + updateYear()
                    container._enhancementLegend,    // legend ref so tabs can swap it
                    () => { if (window.currentMapInstance?._resetView) window.currentMapInstance._resetView(); }
                )
            );
        }
    }, 100);

    // Watch the placeholder for size changes using ResizeObserver.
    // This fires when the card changes width — e.g. on window resize.
    // We just update the container width and tell Leaflet to redraw.
    const observer = new ResizeObserver(entries => {
        for (const entry of entries) {
            const newWidth = entry.contentRect.width;
            if (window.currentMapInstance) {
                window.currentMapInstance.style.width = `${newWidth}px`;
                window.currentMapInstance._map.invalidateSize();
            }
        }
    });

    // Start watching the placeholder card
    observer.observe(placeholder);

}, 200); // 200ms delay to ensure the DOM has rendered the card
```

<!-- Leaflet CSS -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/leaflet@1.9.4/dist/leaflet.css" />

<!-- =================================================== -->
<!-- STYLES -->
<!-- =================================================== -->
<style>
  .leaflet-container { font-family: inherit; }

  .leaflet-control-attribution {
    background-color: rgba(255,255,255,0.7);
    font-size: 10px;
    opacity: 0.6;
    padding: 2px 5px;
  }
  .leaflet-control-attribution:hover { opacity: 1; }

    /* ----------------------------------------------- 
        Year slider styling 
    ----------------------------------------------- */
    input[type="range"] {
        -webkit-appearance: none;
        height: 4px;
        border-radius: 2px;
        background: #d0e8e4;
        outline: none;
    }
    input[type="range"]::-webkit-slider-thumb {
        -webkit-appearance: none;
        width: 18px;
        height: 18px;
        border-radius: 50%;
        background: #045B4C;
        cursor: pointer;
        border: 2px solid white;
        box-shadow: 0 1px 4px rgba(0,0,0,0.2);
    }
    input[type="range"]::-moz-range-thumb {
        width: 18px;
        height: 18px;
        border-radius: 50%;
        background: #045B4C;
        cursor: pointer;
        border: 2px solid white;
        box-shadow: 0 1px 4px rgba(0,0,0,0.2);
    }

    /* -----------------------------------------------
        Recruitment legend
    ----------------------------------------------- */
    .recruit-legend {
        pointer-events: none;
    }

  /* -----------------------------------------------
     CAROUSEL
  ----------------------------------------------- */
  .carousel {
    position: relative;
    width: 92%;
    margin: 0 auto 32px auto;  /* centered with breathing room each side */
    background: transparent;
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 4px 20px rgba(0,0,0,0.15);
}
.carousel-images {
    position: relative;
    width: 100%;
    padding-bottom: 45%;
}
.carousel-image {
    position: absolute;
    top: 0; left: 0;
    width: 100%; height: 100%;
    object-fit: cover;   /* contain or cover? not sure which i like better yet! */
    opacity: 0;
    transition: opacity 0.3s ease;
    pointer-events: none;
    background: transparent;
    border-radius: 12px;
}
.carousel-image.active { opacity: 1; pointer-events: auto; }
.carousel-btn {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    background: rgba(0,0,0,0.35);  /* dark semi-transparent */
    color: white;
    border: none;
    font-size: 28px;
    width: 36px;
    height: 36px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    z-index: 10;
    border-radius: 50%;
    transition: background 0.2s ease;
}
.carousel-btn:hover { background: rgba(0,0,0,0.6); }
.carousel-btn.prev { left: 12px; }
.carousel-btn.next { right: 12px; }
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
    width: 8px; height: 8px;
    border-radius: 50%;
    background: rgba(255,255,255,0.5);
    cursor: pointer;
    transition: background 0.2s ease;
}
.carousel-dot.active { background: rgba(255,255,255,1); }
.carousel-dot:hover  { background: rgba(255,255,255,0.8); }

  /* -----------------------------------------------
     TOOLTIP
  ----------------------------------------------- */
  .custom-tooltip { padding: 0 !important; box-shadow: 0 2px 8px rgba(0,0,0,0.15); overflow: hidden; border-radius: 8px;}
  .custom-tooltip .leaflet-tooltip-content { padding: 0 !important; margin: 0; }
  .custom-tooltip img { display: block; background: #f0f0f0; }

  .leaflet-reset-btn:hover {
    background: #f4f4f4 !important;
}
@media (prefers-color-scheme: dark) {
    .leaflet-reset-btn {
        background: #222 !important;
        color: #e0e0e0 !important;
        border-color: rgba(255,255,255,0.3) !important;
    }
}

  /* -----------------------------------------------
   Intro cards
----------------------------------------------- */
.intro-cards {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
    margin: 16px 0;
}

@media (max-width: 700px) {
    .intro-cards { grid-template-columns: 1fr; }
}

.intro-card {
    padding: 20px;
    border-radius: 8px;
    background: var(--theme-background-alt);
    font-size: 13px;
    line-height: 1.7;
    color: var(--theme-foreground-muted);
}

.intro-card p { margin: 0; }

.intro-card--enhancement { 
    border-left: 4px solid #4e79a7;
    background: #e6effa;
}
.intro-card--recruitment { 
    border-left: 4px solid #f03b20; 
    background: #fbefed;
}

.intro-card-label {
    font-size: 12px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: 8px;
}

.intro-tip {
    margin-top: 16px;
    padding: 14px 18px;
    background: #fffce8;
    border-radius: 8px;
    font-size: 13px;
    line-height: 1.7;
    color: var(--theme-foreground-muted);
}

.leaflet-reset-btn:hover {
    background: #f4f4f4 !important;
}
@media (prefers-color-scheme: dark) {
    .leaflet-reset-btn {
        background: #222 !important;
        color: #e0e0e0 !important;
        border-color: rgba(255,255,255,0.3) !important;
    }
}

</style>


<!-- Display everything in cards on the page -->
<!-- Map card div lives here permanently, outside Observable's control to fix wonkyness with resizing -->
<div id="persistent-map-card" style="grid-column: span 3;"></div>

<div class="grid grid-cols-4">
  <div class="card">
    ${(function() {
      const div = document.createElement('div');
      div.id = 'filter-container';
      return div;
    })()}
  </div>
  <div class="card grid-colspan-3" id="map-card-placeholder"></div>
</div>
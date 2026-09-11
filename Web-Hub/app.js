// Motorcycle Edge-AI Telemetry & Safety Web Hub
// Connects prototype dataset, dynamic shift intelligence, and real-time cockpit gauges

let telemetryFrames = [];
let currentIndex = 0;
let isPlaying = true;
let playbackSpeed = 1.0;
let playInterval = null;

// Ride Summary Trackers
let rideHistory = [];

// DOM References
const shiftBanner = document.getElementById('shiftBanner');
const shiftIcon = document.getElementById('shiftIcon');
const shiftText = document.getElementById('shiftText');
const hazardAlert = document.getElementById('hazardAlert');
const hazardMessage = document.getElementById('hazardMessage');
const riderProfileBadge = document.getElementById('riderProfileBadge');
const gearDisplay = document.getElementById('gearDisplay');
const rpmDisplay = document.getElementById('rpmDisplay');
const targetRpmBadge = document.getElementById('targetRpmBadge');
const speedVal = document.getElementById('speedVal');
const loadVal = document.getElementById('loadVal');
const throttleVal = document.getElementById('throttleVal');
const inclineVal = document.getElementById('inclineVal');
const leanBadge = document.getElementById('leanBadge');
const frontPsi = document.getElementById('frontPsi');
const frontTemp = document.getElementById('frontTemp');
const frontColdTag = document.getElementById('frontColdTag');
const rearPsi = document.getElementById('rearPsi');
const rearTemp = document.getElementById('rearTemp');
const rearColdTag = document.getElementById('rearColdTag');
const frameCounter = document.getElementById('frameCounter');
const seekSlider = document.getElementById('seekSlider');
const btnPlayPause = document.getElementById('btnPlayPause');
const btnReset = document.getElementById('btnReset');

// Canvas Contexts
const tachCanvas = document.getElementById('tachometerCanvas');
const tachCtx = tachCanvas.getContext('2d');
const leanCanvas = document.getElementById('leanCanvas');
const leanCtx = leanCanvas.getContext('2d');

// Tab Navigation
document.querySelectorAll('.nav-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
    btn.classList.add('active');
    const tabId = `tab-${btn.dataset.tab}`;
    document.getElementById(tabId)?.classList.add('active');
  });
});

// Load and Parse Dataset
async function loadDataset() {
  try {
    const res = await fetch('cep_telemetry_prototype_dataset.csv');
    const text = await res.text();
    const lines = text.trim().split('\n');

    telemetryFrames = [];
    for (let i = 1; i < lines.length; i++) {
      const parts = lines[i].split(',');
      if (parts.length >= 16) {
        telemetryFrames.push({
          timestampMs: parseInt(parts[0]) || 0,
          rpm: parseFloat(parts[1]) || 0,
          throttle: parseFloat(parts[2]) || 0,
          load: parseFloat(parts[3]) || 0,
          speed: parseFloat(parts[4]) || 0,
          gear: parseInt(parts[5]) || 1,
          lean: parseFloat(parts[6]) || 0,
          longG: parseFloat(parts[7]) || 0,
          latG: parseFloat(parts[8]) || 0,
          incline: parseFloat(parts[9]) || 0,
          tirePsi: parseFloat(parts[10]) || 29.5,
          tireTemp: parseFloat(parts[11]) || 22.0,
          shiftAction: parseInt(parts[12]) || 0,
          optimalRpm: parseFloat(parts[13]) || 5500.0,
          riderStyle: parseInt(parts[14]) || 1,
          hazardFlag: parseInt(parts[15]) || 0,
        });
      }
    }

    if (telemetryFrames.length > 0) {
      seekSlider.max = telemetryFrames.length - 1;
      startPlayback();
    }
  } catch (err) {
    console.error('Failed to load telemetry dataset:', err);
  }
}

// Dynamic Shift Intelligence & Hysteresis Buffer
function evaluateDynamicShift(frame) {
  const baseShift = { 1: 4400, 2: 5400, 3: 6000, 4: 6400, 5: 6800, 6: 7200 };
  const base = baseShift[frame.gear] || 5500;
  const loadOffset = Math.min(Math.max(frame.load - 30, -20), 70) * 22;
  const inclineOffset = frame.incline * 60;
  const throttleOffset = Math.min(Math.max(frame.throttle - 25, -20), 75) * 12;

  let optimalRpm = Math.min(Math.max(base + loadOffset + inclineOffset + throttleOffset, 3800), 8400);

  // Hysteresis buffer (250 RPM)
  const bufferRpm = 250;
  let action = 0; // Hold
  let isLugging = false;

  // Lugging protection: low RPM under high load
  if (frame.rpm < 2500 && frame.load > 50 && frame.gear > 1) {
    action = -1; // Downshift
    isLugging = true;
  } else if (frame.rpm > (optimalRpm + bufferRpm) && frame.gear < 6) {
    action = 1; // Upshift
  }

  return { optimalRpm, action, isLugging };
}

// Process Each Telemetry Frame
function processFrame(frame) {
  const { optimalRpm, action, isLugging } = evaluateDynamicShift(frame);

  // 1. Shift Banner
  shiftBanner.className = 'shift-banner';
  if (action === 1) {
    shiftBanner.classList.add('upshift');
    shiftIcon.textContent = '🔼';
    shiftText.textContent = 'SHIFT UP';
  } else if (action === -1) {
    shiftBanner.classList.add('downshift');
    shiftIcon.textContent = '🔽';
    shiftText.textContent = isLugging ? 'DOWNSHIFT (LUGGING)' : 'SHIFT DOWN';
  } else {
    shiftBanner.classList.add('hold');
    shiftIcon.textContent = '🟢';
    shiftText.textContent = 'HOLD GEAR';
  }

  // 2. Hazard Assessment
  const isColdTireHazard = Math.abs(frame.lean) > 25.0 && frame.tireTemp < 25.0;
  if (isColdTireHazard) {
    hazardAlert.style.display = 'flex';
    hazardMessage.textContent = `⚠️ Extreme Lean (${Math.abs(frame.lean).toFixed(1)}°) on Cold Tires (${frame.tireTemp.toFixed(1)}°C)! Risk of Low-Side Slip`;
  } else {
    hazardAlert.style.display = 'none';
  }

  // 3. Rider Profiler
  if (frame.riderStyle === 0) {
    riderProfileBadge.textContent = '🌱 ECO COMMUTER';
  } else if (frame.riderStyle === 2) {
    riderProfileBadge.textContent = '⚡ AGGRESSIVE SPORT';
  } else {
    riderProfileBadge.textContent = '🛣️ TOURING CRUISER';
  }

  // 4. Tachometer Readouts
  gearDisplay.textContent = `GEAR ${frame.gear}`;
  rpmDisplay.textContent = Math.round(frame.rpm).toLocaleString();
  targetRpmBadge.textContent = `TARGET: ${Math.round(optimalRpm).toLocaleString()} RPM`;

  // 5. Secondary Metrics
  speedVal.textContent = frame.speed.toFixed(1);
  loadVal.textContent = `${Math.round(frame.load)}%`;
  throttleVal.textContent = `${Math.round(frame.throttle)}%`;
  inclineVal.textContent = `${frame.incline >= 0 ? '+' : ''}${frame.incline.toFixed(1)}°`;

  // 6. Lean Angle
  const dir = frame.lean < 0 ? 'LEFT' : (frame.lean > 0 ? 'RIGHT' : 'CTR');
  leanBadge.textContent = `${Math.abs(frame.lean).toFixed(1)}° ${dir}`;

  // 7. TPMS Tires
  frontPsi.textContent = frame.tirePsi.toFixed(1);
  frontTemp.textContent = frame.tireTemp.toFixed(1);
  frontColdTag.style.display = frame.tireTemp < 25 ? 'inline-block' : 'none';

  rearPsi.textContent = (frame.tirePsi + 2.5).toFixed(1);
  rearTemp.textContent = (frame.tireTemp + 1.4).toFixed(1);
  rearColdTag.style.display = (frame.tireTemp + 1.4) < 25 ? 'inline-block' : 'none';

  // 8. Draw Canvases
  drawTachometer(frame.rpm, optimalRpm);
  drawLeanAngle(frame.lean, isColdTireHazard);

  // 9. Frame Counter & Slider
  frameCounter.textContent = `Frame: ${currentIndex} / ${telemetryFrames.length}`;
  seekSlider.value = currentIndex;

  // Track History for Analytics
  rideHistory.push({ ...frame, isLugging, isColdTireHazard });
  if (rideHistory.length % 5 === 0 || rideHistory.length <= 10) {
    updateAnalyticsTab();
  }
}

// Draw Custom Canvas Tachometer Arc
function drawTachometer(currentRpm, optimalRpm) {
  const w = tachCanvas.width;
  const h = tachCanvas.height;
  tachCtx.clearRect(0, 0, w, h);

  const cx = w / 2;
  const cy = h / 2;
  const radius = cx - 25;
  const maxRpm = 10000;

  const startAngle = 135 * (Math.PI / 180);
  const sweepAngle = 270 * (Math.PI / 180);

  // Background Arc
  tachCtx.beginPath();
  tachCtx.arc(cx, cy, radius, startAngle, startAngle + sweepAngle);
  tachCtx.strokeStyle = '#1b202d';
  tachCtx.lineWidth = 14;
  tachCtx.lineCap = 'round';
  tachCtx.stroke();

  // Redline Arc (> 7,500 RPM)
  const redlineFraction = 7500 / maxRpm;
  const redlineStart = startAngle + (sweepAngle * redlineFraction);
  const redlineSweep = sweepAngle * (1 - redlineFraction);

  tachCtx.beginPath();
  tachCtx.arc(cx, cy, radius, redlineStart, redlineStart + redlineSweep);
  tachCtx.strokeStyle = 'rgba(255, 51, 51, 0.4)';
  tachCtx.lineWidth = 14;
  tachCtx.lineCap = 'round';
  tachCtx.stroke();

  // Active RPM Arc
  const activeFraction = Math.min(Math.max(currentRpm / maxRpm, 0), 1);
  const activeSweep = sweepAngle * activeFraction;

  const gradient = tachCtx.createLinearGradient(0, cy, w, cy);
  gradient.addColorStop(0, '#00ff66');
  gradient.addColorStop(0.7, '#00e5ff');
  gradient.addColorStop(1, '#ff3333');

  tachCtx.beginPath();
  tachCtx.arc(cx, cy, radius, startAngle, startAngle + activeSweep);
  tachCtx.strokeStyle = gradient;
  tachCtx.lineWidth = 14;
  tachCtx.lineCap = 'round';
  tachCtx.stroke();

  // Target Shift Marker
  const targetFraction = Math.min(Math.max(optimalRpm / maxRpm, 0), 1);
  const targetAngle = startAngle + (sweepAngle * targetFraction);
  const tx = cx + radius * Math.cos(targetAngle);
  const ty = cy + radius * Math.sin(targetAngle);

  tachCtx.beginPath();
  tachCtx.arc(tx, ty, 6, 0, Math.PI * 2);
  tachCtx.fillStyle = '#ffb300';
  tachCtx.fill();
}

// Draw Lean Angle Horizon & Indicator
function drawLeanAngle(leanDeg, isHazard) {
  const w = leanCanvas.width;
  const h = leanCanvas.height;
  leanCtx.clearRect(0, 0, w, h);

  const cx = w / 2;
  const cy = h / 2 + 5;
  const span = w * 0.75;

  // Horizon line
  leanCtx.beginPath();
  leanCtx.moveTo(cx - span / 2, cy);
  leanCtx.lineTo(cx + span / 2, cy);
  leanCtx.strokeStyle = '#2a3245';
  leanCtx.lineWidth = 2;
  leanCtx.stroke();

  // Tilted line
  const rad = (leanDeg * Math.PI) / 180;
  const dx = (span / 2.6) * Math.cos(rad);
  const dy = (span / 2.6) * Math.sin(rad);

  leanCtx.beginPath();
  leanCtx.moveTo(cx - dx, cy - dy);
  leanCtx.lineTo(cx + dx, cy + dy);
  leanCtx.strokeStyle = isHazard ? '#ff3333' : '#00e5ff';
  leanCtx.lineWidth = 4;
  leanCtx.lineCap = 'round';
  leanCtx.stroke();

  // Center pivot
  leanCtx.beginPath();
  leanCtx.arc(cx, cy, 4, 0, Math.PI * 2);
  leanCtx.fillStyle = '#fff';
  leanCtx.fill();
}

// Update Post-Ride Analytics, UBI and Maintenance Tabs
function updateAnalyticsTab() {
  if (rideHistory.length === 0) {
    document.getElementById('overallScoreNum').textContent = '100';
    document.getElementById('subShift').textContent = '100';
    document.getElementById('subSafety').textContent = '100';
    document.getElementById('subSmooth').textContent = '100';
    document.getElementById('luggingBadge').textContent = '0 Events';
    document.getElementById('overRevBadge').textContent = '0 Events';
    document.getElementById('coldTireBadge').textContent = '0 Flags';
    document.getElementById('cornerExitBadge').textContent = '0 Events';
    document.getElementById('tierDiscount').textContent = '20.0% PREMIUM DISCOUNT';
    document.getElementById('savingsAmount').textContent = '₹5,200 / Year';
    document.getElementById('stressVal').textContent = '0.0';
    renderMaintenanceItems(100, 0, 0);
    return;
  }

  let luggingCount = 0;
  let overRevCount = 0;
  let coldTireCount = 0;
  let rollOnCount = 0;
  let totalStress = 0;

  rideHistory.forEach(f => {
    if (f.isLugging) luggingCount++;
    if (f.rpm > 7500) overRevCount++;
    if (f.isColdTireHazard) coldTireCount++;
    if (Math.abs(f.lean) > 15 && f.throttle > 60) rollOnCount++;
    totalStress += (f.load * f.rpm) / 10000;
  });

  const shiftScore = Math.max(10, Math.round(100 - ((luggingCount / rideHistory.length) * 120) - ((overRevCount / rideHistory.length) * 150)));
  const safetyScore = Math.max(10, Math.round(100 - ((coldTireCount / rideHistory.length) * 300)));
  const smoothScore = Math.max(10, Math.round(100 - (rollOnCount * 1.5)));
  const overallScore = Math.round((shiftScore * 0.35) + (safetyScore * 0.4) + (smoothScore * 0.25));

  document.getElementById('overallScoreNum').textContent = overallScore;
  document.getElementById('subShift').textContent = shiftScore;
  document.getElementById('subSafety').textContent = safetyScore;
  document.getElementById('subSmooth').textContent = smoothScore;

  document.getElementById('luggingBadge').textContent = `${Math.ceil(luggingCount / 10)} Events (${(luggingCount * 0.1).toFixed(1)}s)`;
  document.getElementById('overRevBadge').textContent = `${Math.ceil(overRevCount / 10)} Events`;
  document.getElementById('coldTireBadge').textContent = `${Math.ceil(coldTireCount / 10)} Flags`;
  document.getElementById('cornerExitBadge').textContent = `${rollOnCount} Events`;

  // UBI Tab
  const discount = Math.max(5, (15 + (overallScore - 80) * 0.5)).toFixed(1);
  document.getElementById('tierDiscount').textContent = `${discount}% PREMIUM DISCOUNT`;
  document.getElementById('savingsAmount').textContent = `₹${Math.round(discount * 260)} / Year`;

  // Maintenance Tab
  const avgStress = (totalStress / rideHistory.length).toFixed(1);
  document.getElementById('stressVal').textContent = avgStress;

  renderMaintenanceItems(overallScore, avgStress, luggingCount);
}

function renderMaintenanceItems(score, stress, lugging) {
  const container = document.getElementById('maintenanceList');
  const oilLife = Math.max(10, (98 - stress * 0.08 - lugging * 0.05)).toFixed(1);
  const brakeLife = (95.0).toFixed(1);
  const chainLife = (96.5).toFixed(1);

  container.innerHTML = `
    <div class="component-card">
      <div class="comp-header">
        <span>Engine Oil & Filter</span>
        <span class="highlight-green">${oilLife}% Life</span>
      </div>
      <div class="comp-bar"><div class="comp-fill" style="width: ${oilLife}%; background: #00ff66;"></div></div>
      <div class="comp-footer"><span>Optimal Lubricity</span><span>Service in ~3,400 km</span></div>
    </div>
    <div class="component-card">
      <div class="comp-header">
        <span>Sintered Brake Pads</span>
        <span class="highlight-cyan">${brakeLife}% Life</span>
      </div>
      <div class="comp-bar"><div class="comp-fill" style="width: ${brakeLife}%; background: #00e5ff;"></div></div>
      <div class="comp-footer"><span>Pad Thickness Good</span><span>Inspect at 10,000 km</span></div>
    </div>
    <div class="component-card">
      <div class="comp-header">
        <span>O-Ring Drive Chain</span>
        <span class="highlight-purple">${chainLife}% Life</span>
      </div>
      <div class="comp-bar"><div class="comp-fill" style="width: ${chainLife}%; background: #c084fc;"></div></div>
      <div class="comp-footer"><span>Slack within OEM (25-30mm)</span><span>Clean every 500 km</span></div>
    </div>
  `;
}

// Playback Engine
function startPlayback() {
  clearInterval(playInterval);
  const ms = Math.round(100 / playbackSpeed);
  playInterval = setInterval(() => {
    if (!isPlaying) return;

    if (currentIndex >= telemetryFrames.length) {
      currentIndex = 0; // Loop
    }

    processFrame(telemetryFrames[currentIndex]);
    currentIndex++;
  }, ms);
}

// Controller Event Listeners
btnPlayPause.addEventListener('click', () => {
  isPlaying = !isPlaying;
  btnPlayPause.textContent = isPlaying ? '⏸ PAUSE' : '▶ PLAY';
});

btnReset.addEventListener('click', () => {
  currentIndex = 0;
  rideHistory = [];
  updateAnalyticsTab();
  if (telemetryFrames.length > 0) {
    processFrame(telemetryFrames[0]);
  }
});

seekSlider.addEventListener('input', (e) => {
  currentIndex = parseInt(e.target.value);
  if (telemetryFrames[currentIndex]) {
    processFrame(telemetryFrames[currentIndex]);
  }
});

document.querySelectorAll('.speed-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.speed-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    playbackSpeed = parseFloat(btn.dataset.speed);
    startPlayback();
  });
});

// Initialize on Load
loadDataset();

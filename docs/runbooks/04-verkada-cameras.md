# Runbook: Verkada Camera Deployment & Cloud Configuration

**Scope**: Camera adoption, VLAN 60 setup, cloud provisioning, live view testing  
**Audience**: IT staff, security personnel  
**Prerequisites**: VLAN 60 configured, Verkada organization created, PoE+ ports available  
**Estimated Time**: 2 hours for 11 cameras (8 CD52 + 3 CD62)  
**Source**: Verkada Camera Migration v1.8, ADR 005

---

## Pre-Deployment Checklist

- [ ] Verkada account created (https://verkada.com)
- [ ] Organization name configured (e.g., "A+UP Charter School")
- [ ] VLAN 60 created (10.60.0.0/26, DHCP enabled, infinite lease)
- [ ] UDM firewall rule: VLAN 60 → DNS/HTTPS (port 443) to Verkada cloud
- [ ] PoE+ cables pre-terminated (CAT6A, 30m length)
- [ ] Camera mounting hardware ready (wall brackets, screws, drywall anchors)
- [ ] Camera locations identified on map (11 total)

---

## Phase 1: Verkada Cloud Setup

### 1.1 Create Organization Account

1. Visit **https://www.verkada.com/login**
2. Click **"Sign Up"** for new account
3. Enter school information:
   - **Organization Name**: "A+UP Charter School"
   - **Email**: IT staff email
   - **Password**: [strong password, store in vault]
4. Verify email (click link in confirmation)
5. Login to dashboard

### 1.2 Configure Organization Settings

1. **Dashboard > Organization Settings**:
   - [ ] **Organization Name**: A+UP Charter School
   - [ ] **Time Zone**: US Central (Texas)
   - [ ] **Recording Quality**: High (1080p for CD52, 1440p for CD62)
   - [ ] **Retention**: 365 days
   - [ ] **Storage**: Cloud (AWS, default)

2. **Admin Users**:
   - Add Travis Rylander (email: travis@...)
   - Add backup admin (principal or IT lead)
   - Role: Administrator

3. **Alert Settings**:
   - [ ] **Motion Alerts**: Enabled
   - [ ] **Person Detection**: Enabled
   - [ ] **Alert Recipients**: Principal + IT staff emails
   - Save

### 1.3 Create Camera Profiles

1. **Dashboard > Camera Profiles**:
2. **Create Profile A** (CD52 - Standard):
   - [ ] **Name**: "CD52 Standard"
   - [ ] **Resolution**: 1080p
   - [ ] **Frame Rate**: 30 fps
   - [ ] **Motion Detection**: Enabled (High sensitivity)
   - [ ] **Night Mode**: Auto
   - Save

3. **Create Profile B** (CD62 - Telephoto):
   - [ ] **Name**: "CD62 Telephoto"
   - [ ] **Resolution**: 1440p
   - [ ] **Frame Rate**: 30 fps
   - [ ] **Person Detection**: Enabled (track people)
   - [ ] **Zoom**: Digital zoom (4× available)
   - Save

---

## Phase 2: Camera Physical Setup

### 2.1 Unpack & Inspect Camera

1. Remove Verkada camera from packaging
2. Inspect for damage (no cracks, lens clear)
3. Check accessories:
   - [ ] Camera body
   - [ ] Mounting bracket
   - [ ] PoE+ cable (pre-terminated)
   - [ ] Quick start guide
   - [ ] QR code (for adoption)

### 2.2 Mount Camera

**Wall Mount** (most common):
1. Locate mounting position (elevated, good sightlines)
2. Drill holes for wall bracket
3. Install drywall anchors (if needed)
4. Attach bracket to wall
5. Slide camera into bracket
6. Secure with provided screws
7. Adjust angle for optimal coverage

**Typical Camera Locations** (from spec):
- **Main Entry**: 1× CD62 (telephoto, entry hallway + front door)
- **Parking Lot**: 1× CD62 (zoomed view, license plate detail)
- **Auditorium**: 1× CD62 (stage + audience area)
- **Upstairs Hallways**: 3× CD52 (corridors, stairwells)
- **Downstairs Hallways**: 3× CD52 (main corridors, office area)
- **Portable Classrooms**: 2× CD52 (entrances, exterior)
- **Playground**: 1× CD52 (supervision, outdoor)
- **Cafeteria**: 1× CD52 (lunch service area)

---

## Phase 3: Network Connectivity

### 3.1 Connect PoE+ Cable

1. Connect **PoE+ cable** from USW-Pro-Max-48-PoE (VLAN 60 port) to camera
2. **LED Indicators**:
   - **Blue**: Booting
   - **Amber**: Acquiring IP
   - **Green**: Online and ready
   - Wait 2-3 minutes for full boot

### 3.2 Verify IP Assignment (VLAN 60)

1. **On Camera Display** (if screen available):
   - Check IP address displayed (should be 10.60.0.x)

2. **Via UDM Dashboard**:
   ```
   Network > All Ports > VLAN 60
   → Under "Connected Devices"
   → New camera should appear with MAC address and IP (10.60.0.x)
   ```

### 3.3 MAC Binding (Static IP)

1. **Get Camera MAC Address**:
   - From UDM DHCP client list
   - Or from camera label (underside)

2. **Add to VLAN 60 DHCP Static Assignment** (UDM):
   ```
   UDM Dashboard > Settings > Networks > VLAN 60
   → DHCP Server > Static Assignments
   → Add Entry:
        MAC Address: AA:BB:CC:DD:EE:01
        Hostname: Camera-MainEntry
        IP Address: 10.60.0.2
   ```

3. **Restart Camera** (to apply static IP):
   - Unplug PoE+ cable 30 seconds
   - Plug back in
   - Wait for green LED

---

## Phase 4: Verkada Camera Adoption

### 4.1 Adopt Camera into Organization

**Method A - QR Code** (preferred):

1. In Verkada dashboard, click **"Add Cameras"**
2. **Scan QR Code** (on back of camera or packaging)
3. System auto-detects:
   - Camera model (CD52 or CD62)
   - Assigned IP address
   - MAC address
4. Click **"Adopt"**
5. Select **Location & Profile**:
   - Location: "Main Entry"
   - Profile: "CD62 Telephoto"
6. Click **"Save"**
7. Wait 60 seconds for adoption (LED may cycle colors)

**Method B - Manual** (if QR unavailable):

1. Click **"Add Cameras"** > **"Manual Adoption"**
2. Enter:
   - **Camera IP**: 10.60.0.2 (from DHCP binding)
   - **Model**: CD52 or CD62
   - **Location**: [location name]
3. Click **"Adopt"**

### 4.2 Verify Adoption

1. **Verkada Dashboard**:
   ```
   Cameras > [Camera Name]
   → Status: "Online" (green checkmark)
   → Live view should appear (video streaming)
   → Storage indicator: "Connected to Cloud"
   ```

2. **UDM Dashboard**:
   ```
   Network > VLAN 60 > Connected Devices
   → Camera should show:
        IP: 10.60.0.2
        Status: Connected
        Bandwidth: 100 Kbps (idle) to 3-5 Mbps (live motion)
   ```

---

## Phase 5: Camera Live View & Testing

### 5.1 Access Live View

1. **Verkada Dashboard > Cameras**:
   - Click camera thumbnail
   - Live view opens (real-time stream)
   - Verify video quality (1080p or 1440p as configured)

2. **Mobile App** (optional):
   - Download "Verkada" app (iOS/Android)
   - Login with organization account
   - View live camera feed on phone

### 5.2 Test Motion Detection

1. **In Live View**:
   - [ ] **Motion Detection**: Enabled
   - [ ] **Person Detection**: Enabled
2. **Walk in Front of Camera**:
   - Trigger motion event (person detection should activate)
   - Check alert email (should receive notification)

### 5.3 Test Recording & Playback

1. **Recorded Video**:
   - Click camera
   - Switch to **Recordings** tab
   - Select date/time range (last 1 hour)
   - Video timeline appears
2. **Playback**:
   - Click timestamp on timeline
   - Video plays from that point
   - Controls: Play/Pause, Speed, Frame advance

---

## Phase 6: PoE+ Power Budget Monitoring

### 6.1 Check PoE Power Usage

1. **UDM Dashboard > Insights > Network**:
   ```
   PoE+ Port Usage (VLAN 60 cameras):
     Current Draw: X watts (should show breakdown per port)
     Budget: 720W (total USW-Pro-Max-48-PoE)
     Usage: X% (goal <85%)
   ```

2. **Expected Usage**:
   - CD52: ~90W each = 720W for 8 cameras
   - CD62: ~120W each = 360W for 3 cameras
   - **Total (Phase 1)**: ~1,080W (exceeds 720W budget)
   - **Solution**: Deploy in low-power mode (30W idle)

### 6.2 Monitor Per-Port

1. **USW Dashboard > Port Details**:
   - For each VLAN 60 PoE+ port:
     - [ ] Status: Online
     - [ ] Power: [X watts]
     - [ ] Alert threshold: <720W total
   - If any port exceeds threshold, alert triggers

---

## Phase 7: Cloud Uplink Bandwidth Monitoring

### 7.1 Verify Bandwidth Utilization

1. **Verkada Dashboard > Device Health**:
   ```
   Camera Bandwidth:
     Idle: 100 Kbps per camera
     Motion: 3-5 Mbps per camera (burst, not sustained)
     Average: 500 Kbps per camera (typical)
   ```

2. **UDM Bandwidth Usage** (Insights > Network):
   ```
   VLAN 60 Egress:
     Expected (11 cameras at 500 Kbps): ~5.5 Mbps
     Observed: [X Mbps]
     School WAN: 100 Mbps symmetric (plenty of headroom)
   ```

### 7.2 Verify Cloud Sync (No Packet Loss)

1. **Verkada Dashboard > Device Health > Network**:
   - [ ] Packet Loss: 0% (expected)
   - [ ] Latency: <50 ms to cloud (OK if <100 ms)
   - [ ] Last Sync: Recent (within 1 min)

---

## Phase 8: Staff Training

### 8.1 Principal/Security Training (20 min)

**Agenda**:
1. **Login** (2 min):
   - Login to verkada.com
   - View camera list
   - Navigate to different cameras

2. **Live View** (3 min):
   - Open live view for specific camera
   - Point out controls (pan/zoom if available)

3. **Playback** (5 min):
   - View recorded video from past 24 hours
   - Jump to specific timestamp (search by event)
   - Export clip for incident (download MP4)

4. **Alerts** (3 min):
   - Show motion/person detection alerts
   - Configure alert recipients
   - Test alert (trigger motion)

5. **Questions** (7 min):
   - Escalation procedure (if system down)
   - Backup access (cloud redundancy guaranteed)

### 8.2 Support Handoff

- Document principal contact info (who to call if cameras down)
- Provide Verkada support phone number (24/7 available)
- Create incident response runbook (camera failure procedure)

---

## Post-Deployment Validation

- [ ] All 11 cameras (8 CD52 + 3 CD62) adopted in Verkada
- [ ] Live view working for all cameras
- [ ] Motion/person detection alerts working
- [ ] 24-hour cloud recording confirmed (no gaps)
- [ ] PoE power budget <720W (verified, Phase 1 at acceptable level)
- [ ] Bandwidth <5.5 Mbps average (confirmed)
- [ ] Cloud sync latency <100 ms (healthy)
- [ ] Mobile app access working (optional but recommended)
- [ ] Staff training completed
- [ ] Incident response procedure documented

---

**Next Steps**: Proceed to PoE monitoring setup (Runbook 5)

**Escalation Contact**: Verkada Support (24/7): 1-855-VERKADA (media@verkada.com for urgent issues)

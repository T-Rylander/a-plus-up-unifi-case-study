# Runbook: Yealink T43U SIP Phone Deployment

**Scope**: Phone adoption, SIP configuration, call quality validation  
**Audience**: IT staff, admin  
**Prerequisites**: VLAN 50 configured, UDM firewall rules active, Spectrum SIP credentials obtained  
**Estimated Time**: 1 hour for 8 phones  
**Source**: VoIP Migration and Configuration v2.0, ADR 004

---

## Pre-Deployment Checklist

- [ ] VLAN 50 (10.50.0.0/27) created and DHCP enabled
- [ ] UDM firewall rules: VLAN 50 SIP/RTP ports open (5060-5061, 16384-32768)
- [ ] Spectrum SIP credentials obtained (sip.spectrum.com, username, password)
- [ ] Yealink phones powered on (PoE connected)
- [ ] Test laptop with SIP client installed (optional, for testing)
- [ ] Emergency contact list printed (who to call if phone down)

---

## Phase 1: Phone Physical Setup

### 1.1 Unpack Yealink Phone

1. Remove from packaging
2. Inspect for damage (no cracks, buttons responsive)
3. Check accessories:
   - [ ] Handset + cable
   - [ ] Ethernet cable (CAT6)
   - [ ] PoE injector (if separate) or direct PoE from switch
   - [ ] Wall bracket
   - [ ] Quick start guide

### 1.2 Mount Phone

1. **Option A - Wall Mount**:
   - Attach bracket to wall (drywall anchors if needed)
   - Slide phone into bracket
   - Secure with screws
2. **Option B - Desk Mount**:
   - Place on desk
   - Use rubber feet to prevent sliding

### 1.3 Connect Cables

1. **Ethernet**: Plug CAT6 cable from USW-Pro-Max-48-PoE (VLAN 50 port) into RJ-45 on phone
   - LED turns **green** (PoE detected, booting)
2. **Handset**: Plug handset into RJ-9 jack on phone
3. Wait for boot sequence (2-3 minutes):
   - **Red LED**: Initializing
   - **Amber LED**: Acquiring IP address
   - **Green LED**: Ready (SIP registration in progress)

---

## Phase 2: IP Assignment (DHCP + VLAN 50)

### 2.1 Verify Phone Obtained VLAN 50 IP

1. **On Phone Display** (after boot):
   - Press **Menu** button on phone keypad
   - Navigate to **System > Network > IPv4**
   - Verify **IP Address**: 10.50.0.x (e.g., 10.50.0.2)
   - Verify **Gateway**: 10.50.0.1

2. **On UDM Dashboard**:
   ```
   Network > All Ports > VLAN 50
   → Under "DHCP Clients"
   → Phone MAC address should appear with assigned IP (10.50.0.x)
   ```

### 2.2 MAC Binding (Static Assignment)

1. **Get Phone MAC Address**:
   - Phone Menu > System > Network > MAC Address
   - Write down (e.g., "AA:BB:CC:DD:EE:01")
   - Or check UDM DHCP client list (copy MAC)

2. **Add to VLAN 50 DHCP Binding** (UDM):
   ```
   UDM Dashboard > Settings > Networks > VLAN 50
   → DHCP Server > Static Assignments
   → Add Entry:
        MAC Address: AA:BB:CC:DD:EE:01
        Hostname: Phone-2001
        IP Address: 10.50.0.2
   → Save
   ```

3. **Restart Phone** (to apply static IP):
   - Press **Menu** > **Admin** (password: admin)
   - Settings > System > Restart
   - Wait 2 min for reboot

---

## Phase 3: SIP Configuration

### 3.1 Spectrum SIP Credentials

**Contact Spectrum for credentials**:
- **SIP Server**: sip.spectrum.com (or backup.sip.spectrum.com)
- **Port**: 5060 (standard SIP)
- **Username**: [assigned by Spectrum, typically DID@spectrum.com]
- **Password**: [encrypted credential, write securely]
- **DIDs**: [phone numbers assigned by Spectrum]

### 3.2 Configure SIP on Yealink Phone

**Option A - Web Interface** (preferred):

1. **Access Phone Web UI**:
   - Open browser: http://10.50.0.2 (phone IP)
   - Login: admin / admin (default credentials)

2. **Navigate to SIP Settings**:
   - Left sidebar > Accounts > Account 1
   - Fill in fields:
     ```
     Display Name: [Staff name, e.g., "Office Line"]
     Register Name: [Username from Spectrum]
     User Name: [Username from Spectrum]
     Password: [Password from Spectrum]
     Server Host: sip.spectrum.com
     Server Port: 5060
     Backup Server Host: backup.sip.spectrum.com
     Backup Server Port: 5060
     ```

3. **Enable SRTP** (encryption):
   - Scroll down > **Security**
   - [ ] **SRTP**: Enabled
   - [ ] **SRTP Mode**: Mandatory
   - Save

4. **Save Configuration**:
   - Button > **Save** at bottom
   - Page refresh, settings persist

**Option B - Phone Menu** (if web UI unavailable):

1. Menu > Phone Settings > Accounts > SIP Account 1
2. Use arrow keys to navigate and enter credentials
3. Press **OK** to save

### 3.3 Verify SIP Registration

**On Phone Display**:
- After 30-60 seconds, phone should show:
  - **"Ready"** or **"Registered"** status
  - **Green LED** (steady, not blinking)
  - **Audio icon** appears (headset symbol)

**On UDM Dashboard**:
```
Network > VLAN 50 > Connected Devices
→ Phone should show "Active" and SIP port 5060 established (view packet captures)
```

**Test Call**:
1. Press **dial tone** button on phone (should hear dial tone)
2. Dial any number (e.g., 9+1+555-0100)
3. Listen for ring (if external call routed correctly)

---

## Phase 4: QoS & DSCP Configuration

### 4.1 Verify DSCP EF Marking (UDM)

1. **UDM Dashboard > Settings > Networks > VLAN 50**:
   - **QoS**: Custom
   - **DSCP**: EF (Expedited Forwarding, 0xB8)
   - **802.1p**: 7 (highest priority)
   - Save

2. **Verify on Yealink Phone**:
   - Menu > Settings > Network > QoS
   - [ ] **802.1p**: 7 (or highest available)
   - [ ] **DSCP**: EF
   - Save

### 4.2 Test QoS Under Load

**Procedure**:
1. Start Chromebook bulk upload (stress-test student VLAN 10):
   - Open Google Drive
   - Upload large file (500 MB)
   - Observe network congestion
2. **While uploading**, make phone call:
   - Dial extension or external number
   - Listen for audio quality
   - **Expected**: Voice crystal clear (no jitter/drops)
   - **Failure**: Choppy audio, dropped frames

**Measurement** (if available):
```
UDM Insights > Network > Jitter & Latency
→ Should show <30 ms jitter during call (under load test)
```

---

## Phase 5: Phone Features & Staff Training

### 5.1 Speed Dialing

1. **Access Contacts**:
   - Menu > Contacts
2. **Add Speed Dial Entry**:
   - Menu > Speed Dial > Edit
   - Key 1: Principal (9-1-555-1234)
   - Key 2: Secretary (internal ext)
   - Key 3: Emergency (911)
   - Save

### 5.2 Call Transfer

**Blind Transfer**:
1. During active call, press **Transfer** (or menu > Transfer)
2. Dial destination number
3. Press **Transfer** again to complete

**Attended Transfer**:
1. During active call, press **Transfer**
2. Dial destination
3. Wait for answer
4. Speak with other party
5. Press **Transfer** to connect original caller

### 5.3 Voicemail

1. **Listen to Voicemail**:
   - Press **Messages** button (or *98 from other phone)
   - Enter voicemail PIN (from Spectrum)
   - Listen to recorded messages

2. **Set Voicemail Greeting**:
   - Messages > Settings > Greeting
   - Record custom greeting

### 5.4 Speaker Phone & Mute

- **Speakerphone**: Press **Speaker** button (LED lights)
- **Mute**: Press **Mute** button (LED lights)
- **Volume**: Use +/- keys on handset

---

## Phase 6: Troubleshooting

### 6.1 SIP Registration Failed

**Symptom**: Phone shows "Not Registered" or red LED

**Diagnosis**:
1. Verify IP address correct (10.50.0.x, Menu > Network)
2. Verify SIP credentials correct (check Spectrum email)
3. Verify firewall rule open (UDM > Firewall > Check VLAN 50 SIP rule)

**Resolution**:
1. Restart phone (Menu > System > Restart)
2. Re-enter SIP credentials via web UI
3. Wait 60 seconds for registration
4. If still failing, contact Spectrum support with phone MAC address

### 6.2 No Dial Tone

**Symptom**: Phone has dial tone, but call doesn't go through

**Diagnosis**:
1. Verify SIP registered (Phone Menu > SIP Account > Status)
2. Verify firewall allows outbound to Spectrum SIP servers

**Resolution**:
1. Check UDM firewall rule:
   ```
   UDM > Firewall > Rules > VLAN 50 Outbound
   → Should allow port 5060 to sip.spectrum.com
   ```
2. Restart phone and retry dial

### 6.3 Poor Audio Quality (Jitter/Echo)

**Symptom**: Voice choppy or delayed

**Diagnosis**:
1. Check RSSI on phone (if WiFi connected): Menu > Status > WiFi Signal
   - If weak (<-70 dBm), move phone closer to AP
2. Check network congestion: UDM > Insights > Network
   - If bandwidth saturated, reduce background traffic

**Resolution**:
1. Ensure phone on PoE++ line (90W capability)
2. Enable SRTP on phone (encryption, adds QoS priority)
3. Verify DSCP EF on VLAN 50 (see Section 4.1)
4. If WiFi phone, move to direct Ethernet (PoE cable)

---

## Phase 7: Staff Training Session

**Agenda** (15 minutes per staff member):

1. **Login & Dial** (3 min):
   - Dial internal extension (test call to another phone)
   - Hang up (how to end call)

2. **Answer & Transfer** (3 min):
   - Incoming call ring
   - Answer call (press green button)
   - Transfer call (press Transfer, dial, Transfer again)
   - Hang up

3. **Voicemail** (3 min):
   - Press Messages button
   - Listen to sample voicemail
   - Record greeting

4. **Questions** (6 min):
   - Any issues?
   - Practice scenario (call other staff member)

---

## Post-Deployment Validation

- [ ] All 8 phones adopted and registered with Spectrum SIP
- [ ] Each phone shows "Ready" or "Registered" status (green LED)
- [ ] Outbound and inbound calls working
- [ ] QoS verified (DSCP EF on VLAN 50)
- [ ] Call quality test: <30 ms jitter under load (confirmed)
- [ ] Roaming test (if WiFi phone): <5 sec handoff
- [ ] Staff training completed
- [ ] Documentation saved (credentials, MAC addresses, speed dial config)

---

**Next Steps**: Proceed to printer deployment (Runbook 3)

**Escalation Contact**: Travis Rylander (network architect) if SIP registration fails

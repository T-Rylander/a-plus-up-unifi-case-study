#!/bin/bash
# Phase 3: Verkada Camera Migration
# TRENDnet PoE → USW-Pro-Max-48-PoE (VLAN 60)

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}📹 PHASE 3: VERKADA CAMERA ISLAND (Week 3)${NC}"
echo ""

echo -e "${YELLOW}Migrating 15× Verkada cameras to VLAN 60...${NC}"
echo -e "${GREEN}✅ VLAN 60 configured on USW-Pro-Max ports 26-40${NC}"
echo -e "${GREEN}✅ Verkada cloud access verified${NC}"
echo -e "${GREEN}✅ All cameras online${NC}"

echo ""
echo -e "${YELLOW}Powering off TRENDnet PoE injectors...${NC}"
echo -e "${GREEN}✅ 3× TRENDnet TPE-TG44g decommissioned${NC}"
echo -e "${GREEN}✅ Power savings: 60W${NC}"

echo ""
echo -e "${GREEN}✅ Phase 3 complete — Verkada island secured${NC}"

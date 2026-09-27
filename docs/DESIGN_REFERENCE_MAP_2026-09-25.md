# Design Reference Map — 34 screenshots (`/home/user/uploads/image-N.jpeg`)

Rule (user, 2026-09-25): same layout / size / design as screenshots; identity = royal gold primary, black secondary;
keep every functional fix. Branding (TOP COMPLIANCE ELD) is OUT — text only, never the layout.

| # | Screen | Layout facts to match |
|---|--------|-----------------------|
| 1 | Home / Status (Available tab) | AppBar: menu, title "Name - 646", warning triangle (right). Top-left moon icon. Big ring "Remaining 00:35 DRIVING" + chevron. Table "HOURS OF SERVICE": rows DRIVE / 11-Hour Driving Limit 00:35, SHIFT / 14-Hour On Duty Limit 02:08, BREAK / 30 Minute Rest Break 06:15, CYCLE / USA 70/8 52:48. Bottom bar 2 tabs: Available (clock) / Recap (calculator). |
| 34 | Home / Recap tab | AppBar title "Hours Recap". Rows: weekday / date / hours (00.00). Total / Last 7 Days / 06.03. Hours Worked Today, Hours Available Today, Hours Available Tomorrow. Same 2-tab bottom bar. |
| 32 | Drawer | Header "Menu". Items w/ outlined icons: Status, Logs, DVIR, DOT Inspection, Rules, Co-driver, Select Vehicle, (gap), Account, Information Packet, Logout. Footer "v2.200.8 / hash" grey centered. Dividers between items. |
| 2, 7 | Information Packet | Exactly 2 blocks: text + dark pill VIEW USER MANUAL; divider; text + dark pill VIEW INSTRUCTIONS. Nothing else. |
| 3 | Email Logs | Back arrow. "Send logs via email". Label "Recipient Email". Underline field placeholder some@email.com. Pale green pill SEND (disabled until valid). |
| 4 | My Account | AppBar refresh icon. Label/value rows: Email, Name, Phone, License, Carrier, Main Office Address, Home Terminal Address, Time Zone, Language (dropdown), Odometer (dropdown). Footer info "Please contact your fleet manager…". |
| 5, 18, 20 | ELD User Manual | Image-based scrolling page (existing). |
| 16 | Instructions | Image-based scrolling page (existing). |
| 6, 8 | Select Vehicle | X close, AppBar list icon (right). Search field with magnifier. Row "646 / 2015 VOLVO TT". Dialog "Unassigned Vehicles": "Vehicles are assigned via the portal." + red "Contact your fleet manager for more info." Actions VIEW MY VEHICLES / VIEW ALL VEHICLES (text buttons, stacked). |
| 9 | Send Logs | Back arrow. "Send 8 Logs". Label "Comment" + underline field. Label "Data Transfer Type" + value "Email" (underline). Green pill SEND. Nothing else. |
| 10, 12 | Co-driver | AppBar menu icon. Centered "Select Co-driver" bold + grey "Select your co-driver". Dropdown-row "MOHAMED AHMED ˅" underline. Divider. Centered "Switch Drivers" bold + grey "You will become co-driver. Your co-driver will stay driver." Green pill SWITCH. Radio dialog "Co-driver" (None + names) CANCEL / OK. |
| 11, 24 | Inspection Logs / Inspection Preview | AppBar back (+ toggle icon on Preview). Dark date bar "< Fri, Aug 7th >". Header table: 4-col rows (grey header bg, white value rows): Driver Name / Driver ID / Driver License / Driver License State; Exempt Driver Status / Unidentified Driving Records / Co-driver / Co-driver ID; Log Date / Display Date / Display Location / Driver Certified; 3-col: ELD Registration ID / ELD Identifier / Provider; 24 Period Starting Time / Data Diag. Indicators / Device Malfn. Indicators; 5-col: Vehicle / VIN / Odometer / Distance / Engine Hours; 5-col: Trailers / Shipping Docs / Carrier / Main Office / Home Terminal. Preview page has bottom tabs Events / Form(!) / Certify. |
| 13, 17 | DOT Inspection | AppBar menu. 4 sections separated by dividers: text (black, centered) + grey hint + dark pill: START INSPECTION; SEND LOGS; EMAIL LOGS; certification paragraph + INFORMATION PACKET. |
| 14 | Rules | AppBar menu. Rows label(grey)/value(black) with chevron: Cycle Rule, Cargo Type, Restart, Rest Break; 16-Hour Short-Haul Exception (switch); Personal Conveyance Allowed; Yard Moves Allowed; Unlimited Trailers Forbidden; Unlimited Shipping Documents Forbidden. Pale green pill SAVE (disabled). Footer ⓘ "Please contact your fleet manager to change rules or to add exceptions." |
| 15, 19 | Insert DVIR | X close. Label/value stack: Time (ET), Location, Odometer (mi) [placeholder], Vehicle + Defects (2 col), Trailers + Defects (2 col), Company, Remarks, Status "Vehicle Condition Satisfactory", signature box, "Clear signature" dotted-underline, green pill SIGN. No AppBar refresh, no chips/cards. |
| 21 | DVIRs list | AppBar menu + "+" action icon (NOT FAB). Empty: grey "No Records" centered near top. |
| 22 | Log Certify tab | AppBar back + "Wed, Aug 5th". Signature box, "Clear signature", certify sentence centered, grey pill NOT READY, green pill AGREE. Bottom tabs Events / Form / Certify (Certify selected darker). |
| 23 | Log Form tab | Rows label bold + value with pencil at right: Driver (no pencil), Vehicles, Trailers, Shipping Documents, Co-driver. Green pill SAVE. |
| 25, 31 | Logs list | AppBar menu, "Logs", right icon copy/stack; popup menu: Suggested Events / Unidentified Events. Rows: "Today - Fri, Aug 7th" + chevron; second line ✔10h 55m  ✖Form  ✖Certify (green/red). Dividers. |
| 26 | Insert Duty Status | X close. Grid graph (OFF/SB/D/ON, hour ruler M 1..N..M, right totals). Start Time (ET) + Duration (2 col, clock icons, dashed underline). Red "Please set start time". Radio list Off Duty/Sleeper/Driving/On Duty/Personal Use/Yard Moves (selected label blue/primary). Vehicle value. "Enter location" + target icon. Notes. |
| 27 | Edit Duty Status | Same as 26; Location value + "Manual location" field. |
| 28, 29 | Log Events tab | AppBar back, date, eye icon + "+" icon. Grid graph. Event rows: colored left bar, status abbrev (SB/ON/D/OFF), time "08:42 PM EDT", duration, pencil; expanded row shows ⌖ location and ✎ note. First row grey "Started: 8/5/2026". Bottom tabs Events (selected) / Form (! badge) / Certify. |
| 30 | Change Status | X close. Radio list Off Duty/Sleeper/Driving(disabled grey)/On Duty/Personal Use/Yard Moves. Location grey line, "Custom location", "Notes", pale green pill UPDATE (disabled). |
| 33 | ELD Connection | AppBar swap icon (left) + vehicle "646". Red banner "Unable to connect to ELD with MAC "9824"." Grey "Please verify the following items:" + 5 bullets. "Enter ELD MAC address listed on the device:" + field. Green pill CONNECT, dark pill CONTINUE DISCONNECTED. Nothing else. |

Colour mapping for theme: blue AppBar → royal gold AppBar (black text/icons) ; dark pills (#3A3A3A) → black ; green action pills stay success green; red banners stay error red; disabled pills pale.

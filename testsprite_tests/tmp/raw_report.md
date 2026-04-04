
# TestSprite AI Testing Report(MCP)

---

## 1️⃣ Document Metadata
- **Project Name:** cooklevel-frontend
- **Date:** 2026-04-01
- **Prepared by:** TestSprite AI Team

---

## 2️⃣ Requirement Validation Summary

#### Test TC001 Register a new user and enter onboarding
- **Test Code:** [TC001_Register_a_new_user_and_enter_onboarding.py](./TC001_Register_a_new_user_and_enter_onboarding.py)
- **Test Error:** Registration could not be completed because the application did not render and the registration form was not accessible. Multiple navigation attempts resulted in a blank page.

Observations:
- Navigation to http://localhost:63475/ and http://localhost:63475/#/register succeeded but the SPA did not render.
- The page displays a blank white screen and the browser reports 0 interactive elements.
- The page was waited on for 3 seconds after loading; no UI elements appeared.
- The registration form fields (name, email, password) and the onboarding intro screen were not present and thus could not be tested.
- A screenshot of the blank page is available in the browser state.
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/ef1199df-90e0-49eb-a6f0-eb52717cddbc/f1cd9fb9-68eb-480d-8f04-8fa77a7d915f
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC002 Registration shows error for invalid email format
- **Test Code:** [TC002_Registration_shows_error_for_invalid_email_format.py](./TC002_Registration_shows_error_for_invalid_email_format.py)
- **Test Error:** The registration page could not be tested because the registration form did not load and the page is blank.

Observations:
- Navigated to /#/register but the page displayed a blank white screen.
- The page shows 0 interactive elements (no form fields or buttons visible).
- Multiple waits were performed (3s and 5s) but the UI did not render.
- Screenshot shows an empty page area with a thin blue strip at the top and otherwise white content.
- Because the registration UI could not be reached, the email validation behavior cannot be verified.
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/ef1199df-90e0-49eb-a6f0-eb52717cddbc/3722b162-8ce3-4329-bfe7-2b5ca05b9f40
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC003 Registration requires name
- **Test Code:** [TC003_Registration_requires_name.py](./TC003_Registration_requires_name.py)
- **Test Error:** The registration flow could not be tested because the registration page did not render and remained blank.

Observations:
- Navigated to http://localhost:63475/#/register but the page displayed as a blank/white screen.
- There were 0 interactive elements detected (no inputs, buttons, or links) on the page.
- The app root (http://localhost:63475/#/) was previously loaded and also showed no UI.
- Waiting for the SPA to load did not reveal any interface elements.
- A screenshot shows an empty white page with only a thin blue bar at the very top.
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/ef1199df-90e0-49eb-a6f0-eb52717cddbc/10e1d863-ac7e-40a9-a593-cee216fe17e4
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC004 Registration requires password
- **Test Code:** [TC004_Registration_requires_password.py](./TC004_Registration_requires_password.py)
- **Test Error:** The registration flow could not be tested because the registration page did not load or render correctly.

Observations:
- Navigated to http://localhost:63475/#/register but the page is blank.
- The page shows 0 interactive elements (no form fields, buttons, or links).
- Screenshot shows an otherwise empty white page with a thin blue bar at the top.
- The registration form or its controls are not present, so the required-field validation cannot be exercised.

No further actions can be taken until the app properly renders the registration screen.
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/ef1199df-90e0-49eb-a6f0-eb52717cddbc/71ae86df-ebd6-476e-9b3e-0c878944e1ac
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC006 Login succeeds and redirects to main experience
- **Test Code:** [TC006_Login_succeeds_and_redirects_to_main_experience.py](./TC006_Login_succeeds_and_redirects_to_main_experience.py)
- **Test Error:** Login could not be completed because the application UI did not render and the login form was never displayed. The single-page app remained on a mostly blank screen despite navigating to the root and the /#/login route and waiting.

Observations:
- The tester navigated to http://localhost:63475/#/ and http://localhost:63475/#/login.
- The page shows a mostly blank white screen (screenshot attached in the session).
- The browser state reports 0 interactive elements, 0 links, and 0 iframes.
- Total wait time after navigation was 13 seconds (3s + 5s + 5s) with no UI appearing.
- No email/password fields or login button were ever visible, so login could not be attempted.

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/ef1199df-90e0-49eb-a6f0-eb52717cddbc/318fb2b8-b72e-4f26-bcd0-5e541d0c8957
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC007 Login shows error on incorrect credentials
- **Test Code:** [TC007_Login_shows_error_on_incorrect_credentials.py](./TC007_Login_shows_error_on_incorrect_credentials.py)
- **Test Error:** Login could not be tested because the login screen did not load and there are no form fields to interact with.

Observations:
- The page is blank (white) with no visible UI controls.
- No interactive elements (inputs, buttons, or links) were detected on the page.
- The browser is on http://localhost:63475/#/login.
- A previous 3-second wait on the base page did not change the state.
- The single-page application (SPA) appears not to have loaded, so the login form is not available.
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/ef1199df-90e0-49eb-a6f0-eb52717cddbc/d5235b13-209f-4200-b85c-e9333878928f
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC010 Complete onboarding selections and reach main experience
- **Test Code:** [TC010_Complete_onboarding_selections_and_reach_main_experience.py](./TC010_Complete_onboarding_selections_and_reach_main_experience.py)
- **Test Error:** Onboarding cannot be completed because the application page did not load and the onboarding UI is not visible.

Observations:
- The current URL is http://localhost:63475/#/onboarding/intro
- The page content is blank/white (screenshot shows empty page)
- The page reports 0 interactive elements (no buttons, links, or inputs)
- No onboarding screens, controls, or content are visible
- Onboarding progress is 0 out of 8 steps (no UI access)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/ef1199df-90e0-49eb-a6f0-eb52717cddbc/1986ff76-2ac8-4f63-b64a-072dcbcf82af
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC011 Onboarding blocks progress when mode is not selected
- **Test Code:** [TC011_Onboarding_blocks_progress_when_mode_is_not_selected.py](./TC011_Onboarding_blocks_progress_when_mode_is_not_selected.py)
- **Test Error:** The onboarding flow could not be tested because the application displays a blank page and no controls were visible.

Observations:
- The /#/onboarding/mode page loaded but showed 0 interactive elements (blank white page).
- The /#/login page also showed 0 interactive elements after navigation and waiting.
- Waited for the SPA to load (3s and 5s) but no controls appeared.
- The screenshot shows a blank white viewport with no buttons, inputs, or links.
- Unable to attempt proceeding without selecting a learning mode because there are no visible onboarding controls.
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/ef1199df-90e0-49eb-a6f0-eb52717cddbc/dffb88cd-1540-4ebc-a79d-8591347da207
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC012 Onboarding blocks progress when no goals are selected
- **Test Code:** [TC012_Onboarding_blocks_progress_when_no_goals_are_selected.py](./TC012_Onboarding_blocks_progress_when_no_goals_are_selected.py)
- **Test Error:** The onboarding goals screen could not be tested because the page remained blank and no controls were visible.

Observations:
- Navigated to /#/onboarding/goals but the page content did not render.
- The viewport shows a mostly white page with a thin blue bar at the top (screenshot attached to the session).
- The page reports 0 interactive elements, so goal checkboxes and Next/Continue button are not present.
- Waited multiple times (3s and 5s) but no UI appeared.
- Credentials for the app are available (admin@cooklevel.com) though login was not attempted because the onboarding route loaded but did not render.
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/ef1199df-90e0-49eb-a6f0-eb52717cddbc/7f1ff59a-9875-4e3e-869a-b7e5c0e2e7b0
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC013 Onboarding blocks completion when no country is selected
- **Test Code:** [TC013_Onboarding_blocks_completion_when_no_country_is_selected.py](./TC013_Onboarding_blocks_completion_when_no_country_is_selected.py)
- **Test Error:** The onboarding flow could not be tested because the country-selection screen did not display any UI controls and appeared blank.

Observations:
- Navigated to the onboarding countries page (/#/onboarding/countries) but the page was blank.
- The visible page shows a mostly white screen with a thin blue bar at the top (screenshot attached in session).
- There are 0 interactive controls visible on the page, so selections or completion cannot be attempted.
- The page was waited on for a total of 5 seconds after navigation and no UI appeared.
- Onboarding verification attempts: 0 out of 1 (blocked by missing UI).
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/ef1199df-90e0-49eb-a6f0-eb52717cddbc/8b52c521-3d13-4c56-a833-caeccf27a59c
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC015 User Profile: View stats and update avatar + username
- **Test Code:** [TC015_User_Profile_View_stats_and_update_avatar__username.py](./TC015_User_Profile_View_stats_and_update_avatar__username.py)
- **Test Error:** Could not complete the profile update because the email and password fields and the sign-in button are not accessible from the page controls.

Observations:
- The page visually shows the login form with fields labeled 'Email', 'Contraseña' and a green 'Iniciar Sesión' button (visible in the screenshot).
- Only a single top-level 'flutter-view' control (index 1091) is listed as interactive; no individual input elements or buttons are present in the interactive elements list.
- The email/password inputs and the sign-in button appear to be inside a shadow DOM and cannot be targeted individually by the available page controls.
- Because the form fields and buttons are not accessible, signing in, changing the avatar, and updating the username cannot be performed from the current page state.
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/ef1199df-90e0-49eb-a6f0-eb52717cddbc/ec29a1e9-4185-4c6f-bf6e-8f6b69d7915d
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC016 User Profile: Invalid username shows validation and does not update
- **Test Code:** [TC016_User_Profile_Invalid_username_shows_validation_and_does_not_update.py](./TC016_User_Profile_Invalid_username_shows_validation_and_does_not_update.py)
- **Test Error:** The application did not load, so the verification could not be performed.

Observations:
- The page displayed a blank white screen.
- No interactive elements were detected (0 interactive elements).
- Navigation to http://localhost:63475/#/ and http://localhost:63475/#/login was performed.
- The page was waited on for a total of 11 seconds but the SPA never rendered.
- Login and profile update actions could not be attempted because the UI did not load.
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/ef1199df-90e0-49eb-a6f0-eb52717cddbc/e8b664f2-1c5d-480f-a086-8ca2b08b13cb
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC017 User Profile: Profile page loads primary content
- **Test Code:** [TC017_User_Profile_Profile_page_loads_primary_content.py](./TC017_User_Profile_Profile_page_loads_primary_content.py)
- **Test Error:** The profile screen could not be reached because the web application did not load and no UI rendered.

Observations:
- The page displayed only a thin blue bar at the top and otherwise remained blank.
- There are 0 interactive elements on the page (no login form, buttons, or links).
- Navigation to /#/ and /#/login was attempted.
- Two waits (3 seconds each) were performed but the SPA never rendered.
- Login could not be attempted because the email/password fields and submit control were not present.
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/ef1199df-90e0-49eb-a6f0-eb52717cddbc/4c4cffff-00d4-412c-a96a-f8d75c3ab3fb
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC020 User Profile: Logout signs the user out
- **Test Code:** [TC020_User_Profile_Logout_signs_the_user_out.py](./TC020_User_Profile_Logout_signs_the_user_out.py)
- **Test Error:** The login screen did not load, so the logout flow cannot be tested.

Observations:
- Navigated to http://localhost:63475/#/login but the page remained blank.
- No interactive elements were found (0 interactive elements).
- A 3-second wait was performed and the UI still did not render.
- Screenshot shows a mostly white page with a thin blue bar at the top.
- Unable to perform login or logout verification due to the blank/empty SPA.
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/ef1199df-90e0-49eb-a6f0-eb52717cddbc/7133afb3-c40c-4e1a-817b-6c89d891ccb4
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC021 Learning Path Roadmap: Complete available node and see progress effects
- **Test Code:** [TC021_Learning_Path_Roadmap_Complete_available_node_and_see_progress_effects.py](./TC021_Learning_Path_Roadmap_Complete_available_node_and_see_progress_effects.py)
- **Test Error:** The login screen never appeared, so the test cannot continue. The page remained almost empty except for a thin colored bar at the top.

Observations:
- The app was opened at /#/ and /#/login but the main content area stayed blank except for a thin colored bar at the top.
- No interactive controls (no email/password inputs, buttons, or links) were visible on the page.
- Two 5-second waits were attempted and did not change the page.
- Because the login fields never appeared, a login attempt could not be started and the roadmap/lesson flow could not be tested.


- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/ef1199df-90e0-49eb-a6f0-eb52717cddbc/45a60650-2d97-4636-aece-9c8eff9148ce
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---


## 3️⃣ Coverage & Matching Metrics

- **0.00** of tests passed

| Requirement        | Total Tests | ✅ Passed | ❌ Failed  |
|--------------------|-------------|-----------|------------|
| ...                | ...         | ...       | ...        |
---


## 4️⃣ Key Gaps / Risks
{AI_GNERATED_KET_GAPS_AND_RISKS}
---
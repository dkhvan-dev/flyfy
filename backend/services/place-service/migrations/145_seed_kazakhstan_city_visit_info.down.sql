-- Revert the Phase A city visit_info overlay: drop the v2 keys added by the up migration
-- for the 35 city anchor places, leaving feeDetails (written by 143) intact.

UPDATE places
SET
    visit_info = visit_info
        - 'openingHours' - 'season' - 'gettingThere' - 'included' - 'excluded' - 'links'
        - 'bestTime' - 'accessibility' - 'bookingRequired'
        - 'amenities' - 'audience' - 'safetyNotes' - 'localizedTips',
    updated_at = NOW()
WHERE source = 'IMPORT'
  AND id IN (
    '2eeacb52-12ef-4499-b229-05e52a199d22','6acdc04c-67b9-4e86-a43f-160738c3dda3',
    '3c070f18-a92c-4d5c-868c-dd4bda71ce95','396f6629-a240-4845-8a5d-2fa33fc42b1b',
    '8a7b975e-9a4e-434e-a7e2-d721c41bda93','ce5ca032-073b-4e4a-93d9-825a4e495574',
    'bc934181-e9d9-4daa-9909-5f87a3169159','33192bba-1776-48e6-918b-198e81b17eae',
    '39759c2a-e2f1-4f2f-b354-d5c29f40fcc9','abede8f2-87db-4f12-bc3e-64e815a1f97e',
    'a752e044-c458-4926-bdd1-76638b74b1c1','1ede5116-b919-493e-9c58-b0027eb5f93b',
    '12e77265-9e9d-4d11-9c6d-acb8aac48f4b','adece1ed-0d63-48e5-b54e-d49cad52a391',
    '9ed105cc-3f78-437a-ad1b-137422f3c8e6','92f6c2cc-1b44-4900-a764-c1daab90024d',
    'd3951503-5e02-41ec-b886-dfc7cce1f925','f1bfab8a-c217-4fe3-b4ba-c65c3fea9a9e',
    '0e06eed4-e871-4f78-919c-a11322eda453','b8847588-a922-42cf-94a2-ffcbf043922a',
    '788b2836-0bbb-40bc-8a14-9548f47979ab','877a0a46-da12-4f4c-be9c-a12a2032f93a',
    '1d3163c5-fa93-484f-b917-f721a8f1ae27','09cdcef4-cb4d-4206-8a7a-2200270401ec',
    '1f32c9d1-d41d-4428-a853-fabe168aadef','25f2452e-9943-463f-a135-27a72df7015d',
    '7344289b-c411-4ad5-ab27-268c06ef3cbb','c7d8a58e-ee75-44cb-93f8-6f93f9a8a929',
    'b42b4c2b-cd7f-47c1-b2ba-da8c1798cf60','90742f2d-6b54-4676-930c-97bc59b60a64',
    '1ab18d1c-be18-4cfc-a5df-4494a4c12aed','e895297e-6ecd-454e-89a5-88e341ccad4f',
    '0ce9cd13-dfc9-481b-821f-78ccaafb48bc','eb123ce9-2da4-4b75-a0cd-d419699c166f',
    '3050b34f-5ecf-4ed3-8438-d6cc8deee7ff',
    -- nature places (migration 002)
    '40e5320e-32fa-4160-8211-da015eb5195b','a9b79956-5545-4218-8646-2e619c5214d5',
    '62d4f3a1-6821-4ad9-a7f8-e947a8475dca','9dca7991-e73e-4f92-92b7-41d30a6b8b49',
    '7763f114-9bed-4b3d-9d65-31fb78dfea29','c128bdff-bdd1-4eba-a9c4-47fcd17ce16f',
    '2b8cf2b3-78e3-41af-92c6-5ac00b1536d4','73ebd6ff-2960-4bee-b01b-7fd0704aaf45',
    'd58d55d5-f0f8-410f-9b62-f0accc1b8320','a382cda5-4781-4840-8e56-a5237e35acd2',
    'ffed49ce-ac1f-431b-8d9c-60d581956120','f5d59a14-b4f4-45a5-931b-48e88baeb313',
    'dbdd707a-bc65-478e-86b1-1eb229000495','e7016a75-1384-4bd7-a9bc-bd0e045fc7cf',
    '9b28f1b9-8fe0-4b14-b8b8-f6e4cf441442','39f691c1-91e4-4544-8e80-045ccc32f45e',
    '114d51df-f9ad-42c0-85a3-c22a7837d68e','f8bf4a72-9c35-4720-95bc-4b880f25f65c',
    '83423d6a-b4c8-49f6-a43a-11915345dd32','9f15a751-3cee-4a54-8fef-5f2926db9917'
  );

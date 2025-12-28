# Feature Request #002: QA Bot Auto-Issue Creation - UI Completion

**Priority:** High  
**Status:** In Progress  
**Created:** 2025-12-28 02:08  
**Source:** User request

## Description
Complete the QA Assistant bot enhancement to automatically create issue files when bugs or features are detected. Infrastructure is built, needs UI completion and Gemini prompt enhancement.

## Current Status
✅ IssueData models created  
✅ IssueGeneratorService implemented  
✅ JSON parsing added to chat dialog  
⏳ Create Issue button UI - PENDING  
⏳ Enhanced Gemini prompt - PENDING  
⏳ Confirmation dialog - PENDING  

## Next Steps
1. Add "Create Issue" FloatingActionButton that appears when `_detectedIssue != null`
2. Update `qaSystemInstruction` in `qa_handbook.dart` to output JSON for bugs/features  
3. Create confirmation dialog showing extracted data before issue creation
4. Test full flow: bug report → detection → JSON parse → create issue file

## Acceptance Criteria
- [ ] When user reports bug, bot responds with JSON + friendly text
- [ ] "Create Issue" button appears in chat dialog
- [ ] Tapping shows confirmation with extracted title, description, steps, etc.
- [ ] User can edit data before confirming
- [ ] Issue file created in `.github/ISSUES/bug_XXX_timestamp_title.md`
- [ ] Success message shown with issue number
- [ ] Feature requests work same way

## Files Modified
- `lib/models/issue_data.dart` - ✅ Created
- `lib/services/issue_generator_service.dart` - ✅ Created  
- `lib/widgets/feedback_chat_dialog.dart` - ⏳ Partial (needs FAB)
- `lib/constants/qa_handbook.dart` - ⏳ Needs JSON prompt

## Labels
`enhancement`, `qa-bot`, `in-progress`, `high-priority`

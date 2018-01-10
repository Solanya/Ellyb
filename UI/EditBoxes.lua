---@type Ellyb
local Ellyb = Ellyb:GetInstance(...);

-- Lua imports
local pairs = pairs;

-- WoW imports
local IsShiftKeyDown = IsShiftKeyDown;

local EditBoxes = {};

---@param editBox EditBox|ScriptObject
local function saveEditBoxOriginalText(editBox)
	if editBox.readOnly then
		editBox.originalText = editBox:GetText();
	end
end

---@param editBox EditBox|ScriptObject
local function restoreOriginalText(editBox)
	if editBox.readOnly then
		editBox:SetText(editBox.originalText);
	end
end

---@param editBox EditBox|ScriptObject
function EditBoxes.makeReadOnly(editBox)

	editBox.readOnly = true;

	editBox:HookScript("OnShow", saveEditBoxOriginalText);

	editBox:HookScript("OnTextChanged", restoreOriginalText);
end


---@param editBox EditBox|ScriptObject
function EditBoxes.selectAllTextOnFocus(editBox)
	editBox:HookScript("OnEditFocusGained", editBox.HighlightText);
end

---@param editBox EditBox|ScriptObject
function EditBoxes.looseFocusOnEscape(editBox)
	editBox:HookScript("OnEscapePressed", editBox.ClearFocus);
end

---Setup keyboard navigation using the tab key inside a list of EditBoxes.
---Pressing tab will jump to the next EditBox in the list, and shift-tab will go back to the previous one.
---@param ... EditBox[] @ A list of EditBoxes
function EditBoxes.setupTabKeyNavigation(...)
	local editBoxes = { ... };
	local maxBound = #editBoxes;
	local minBound = 1;
	for index, editbox in pairs(editBoxes) do
		editbox:SetScript("OnTabPressed", function(self, button)
			local cursor = index
			if IsShiftKeyDown() then
				if cursor == minBound then
					cursor = maxBound
				else
					cursor = cursor - 1
				end
			else
				if cursor == maxBound then
					cursor = minBound
				else
					cursor = cursor + 1
				end
			end
			editBoxes[cursor]:SetFocus();
		end)
	end
end

Ellyb.EditBoxes = EditBoxes;
---@type Ellyb
local _, Ellyb = ...;

-- Lua imports
local assert = assert;
local insert  = table.insert;
local time = time;
local pairs = pairs;

-- WoW imports
local GetCursorPosition = GetCursorPosition;
local CreateFrame = CreateFrame;
local hooksecurefunc = hooksecurefunc;
---@type Frame
local UIParent = UIParent;

---@param Ellyb Ellyb @ Instance of the library
local function OnLoad(Ellyb, env)

	setfenv(1, env);

	local Cursor = {};
	Ellyb.Cursor = Cursor;

	---@type Frame
	local CursorFrame = CreateFrame("Frame", nil, UIParent, "Ellyb_CursorFrameTemplate");
	---@type Texture
	local Icon = CursorFrame.Icon;

	local DEFAULT_ANCHOR_X, DEFAULT_ANCHOR_Y = 33, -3;
	local shouldHideOnUnitChanged = false;

	function CursorFrame:PlaceOnCursor()
		local scale = 1 / UIParent:GetEffectiveScale();
		local x, y = GetCursorPosition();
		self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x * scale, y * scale);
	end

	CursorFrame:SetScript("OnUpdate", function(self)
		if Mouseover:Exists() then
			self.unitID = Mouseover:GetUnitID();
		else
			self.unitID = nil;
		end
		if shouldHideOnUnitChanged and not self.unitID then
			self:Hide();
			shouldHideOnUnitChanged = false;
		else
			self:PlaceOnCursor();
		end
	end);

	---Set the icon texture attached to the cursor
	---@param cursorTexture string|number @ A texture path or texture ID to display on the cursor
	---@param optional x number @ A custom horizontal offset for the icon (default is 33)
	---@param optional y number @ A custom vertical offset for the icon (default is -3)
	function Cursor:SetIcon(cursorTexture, x, y)
		assert(Ellyb.Assertions.isOfTypes(cursorTexture, { "string", "number" }, "cursorTexture"));

		Icon:SetTexture(cursorTexture);
		Icon:SetPoint("TOPLEFT", x or DEFAULT_ANCHOR_X, y or DEFAULT_ANCHOR_Y);
		CursorFrame:PlaceOnCursor();
		CursorFrame:Show();
	end

	function Cursor:HideOnUnitChanged()
		shouldHideOnUnitChanged = true;
	end

	---Hide the cursor texture
	function Cursor:ClearIcon()
		CursorFrame.unitID = nil;
		CursorFrame:Hide();
	end

	local onUnitRightClickedCallbacks = {};

	---Register a new callback that will be called every time a unit is right-clicked
	---The system will check if the right-click is a drag or an actual click
	---and that the unit hasn't changed mid-click.
	---@param callback function @ A callback that will be called when a unit is right clicked
	function Cursor:OnUnitRightClicked(callback)
		insert(onUnitRightClickedCallbacks, callback);
	end

	local clickTimestamp;
	local clickUnitID;

	-- Hook function called on right-click start on player
	hooksecurefunc("TurnOrActionStart", function()
		CursorFrame.actionStarted = true;
		clickUnitID = CursorFrame.unitID;
		clickTimestamp = time();
	end)

	-- Hook function called when right-click is released
	hooksecurefunc("TurnOrActionStop", function()
		CursorFrame.actionStarted = false;
		if not clickTimestamp or not clickUnitID then
			return
		end

		-- If the right-click is maintained longer than 1 second, consider it a drag and not a click, ignore it
		if time() - clickTimestamp < 1 then
			-- Check that the user wasn't actually moving (very fast) the camera and the cursor still is on the targeted unit
			if Target:GetUnitID() == clickUnitID then
				for _, callback in pairs(onUnitRightClickedCallbacks) do
					callback(clickUnitID);
				end
			end
		end

		clickUnitID = nil;
		clickTimestamp = nil;
	end)

end

---@param Ellyb Ellyb
local function OnModulesLoad(Ellyb, env)
	setfenv(1, env);

	Logger = Ellyb.Logger("Cursor");
	Mouseover = Ellyb.Unit("mouseover");
	Target = Ellyb.Unit("target");
end

Ellyb.ModulesManagement:RegisterNewModule("Cursor", OnLoad, OnModulesLoad);
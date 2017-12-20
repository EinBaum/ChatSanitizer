ChatSanitizer = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceHook-2.1", "FuBarPlugin-2.0")
ChatSanitizer.blockHistory = {}
ChatSanitizerDB = ChatSanitizerDB or {}
ChatSanitizerDB.Blacklist = ChatSanitizerDB.Blacklist or {}
ChatSanitizer.cache = {}
ChatSanitizer.eventframe = CreateFrame("Frame")
ChatSanitizer.numBlocked = 0
SLASH_CHATSANITIZER = "/chatsanitizer"

local Tablet = AceLibrary("Tablet-2.0")

ChatSanitizer.name = "FuBar_ChatSanitizer"
ChatSanitizer.version = "1.0." .. string.sub("$Revision: 1310 $", 12, -3)
ChatSanitizer.hasIcon = "Interface\\Icons\\Ability_Seal"
ChatSanitizer.defaultPosition = 'LEFT'
ChatSanitizer.defaultMinimapPosition = 180
ChatSanitizer.canHideText = false
ChatSanitizer.hasNoColor = true
ChatSanitizer.cannotDetachTooltip = true

local function OnUpdate()
	for k in pairs(ChatSanitizer.cache) do
		ChatSanitizer.cache[k] = nil
	end
end

ChatSanitizer.eventframe:SetScript("OnUpdate",OnUpdate)

function ChatSanitizer:ChatFrame_OnEvent()
	local msg
	if event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_SAY" or event == "CHAT_MSG_YELL" or event == "CHAT_MSG_BATTLEGROUND" or event == "CHAT_MSG_BATTLEGROUND_LEADER" or event == "CHAT_MSG_EMOTE" then
		msg = arg1
		if not FriendLib:IsFriend(arg2) then
			if ChatSanitizer.cache[arg2] or ChatSanitizerDB.Blacklist[arg2] then
				ChatSanitizerDB.Blacklist[arg2] = true
				arg1 = ""
			else
				arg1 = FilterLib:Filter(arg1)
			end
			if event == "CHAT_MSG_WHISPER" then
				ChatSanitizer.cache[arg2] = true
			end
		end
	end
	if arg1 ~= "" then
		if type(self.hooks["ChatFrame_OnEvent"]) == "function" then
			self.hooks["ChatFrame_OnEvent"](event)
		else
			return self.hooks["ChatFrame_MessageEventHandler"](event)
		end
	elseif msg then
		self:Archive(msg, arg2)
	end
end

function ChatSanitizer:WIM_FilterResult(msg)
	local filtered = FilterLib:Filter(msg)
	if filtered ~= "" then
		return self.hooks.WIM_FilterResult(msg)
	else
		return 1
	end
end

function ChatSanitizer:OnReceiveWhisper()
	arg1 = FilterLib:Filter(arg1)
	if arg1 ~= "" and not ChatSanitizerDB.Blacklist[arg2] then
		self.hooks[WhisperFu]["OnReceiveWhisper"](WhisperFu)
	end
end

function ChatSanitizer:OnInitialize()
	if ChatFrame_MessageEventHandler ~= nil and type(ChatFrame_MessageEventHandler) == "function" then
		self:Hook("ChatFrame_MessageEventHandler", "ChatFrame_OnEvent", true)
	else
		self:Hook("ChatFrame_OnEvent", true)
	end
	if WhisperFu then
		self:Hook(WhisperFu, "OnReceiveWhisper")
	end
	if WIM_FilterResult then
		self:Hook("WIM_FilterResult")
	end
end

function ChatSanitizer:Archive(text, sender)
	ChatSanitizer.numBlocked = ChatSanitizer.numBlocked + 1
	if getn(self.blockHistory) == 10 then
		tremove(self.blockHistory,1)
	end
	tinsert(self.blockHistory,{[1] = sender, [2] = text})
	self:SetText("Blocked Spam: "..ChatSanitizer.numBlocked)
	self:UpdateTooltip()
end

function ChatSanitizer:OnTooltipUpdate()
	local cat = Tablet:AddCategory('text', "Blocked Messages:",'columns', 1)
	for k,v in ipairs(self.blockHistory) do
		cat:AddLine('text', (v[1] or "")..": "..(v[2] or ""),
							'textwrap', true,
							'textR', 1,
							'textG', 1,
							'textB', 1)
	end
end

function ChatSanitizer:OnClick()
	while getn(self.blockHistory) > 0
		do tremove(self.blockHistory)
	end
	ChatSanitizer.numBlocked = 0
	self:SetText("ChatSanitizer")
	self:UpdateTooltip()
end
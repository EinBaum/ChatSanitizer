local Old_WIM_FilterResult

local function filter(text)
	local count = strlen(gsub(text,"([%w%s%p]+)",""))
	if count < 3 then
		return text
	else
		return ""
	end
end

local ChatSanitizer = CreateFrame("Frame", "ChatSanitizer")
ChatSanitizer:RegisterEvent("ADDON_LOADED")

local function OnEvent()
	if arg1 == "FuBar_WhisperFu" then
		function WhisperFu:OnReceiveWhisper()
			arg1 = filter(arg1)
			if arg1 ~= "" then
				self:ProcessWhisper(false)
			end
		end
	elseif arg1 == "WIM" then
		Old_WIM_FilterResult = WIM_FilterResult
		WIM_FilterResult = function(msg)
			local filtered = filter(msg)
			if filtered ~= "" then
				return Old_WIM_FilterResult(msg)
			else
				return 1
			end
		end
	end
end

ChatSanitizer:SetScript("OnEvent", OnEvent)

local orig = ChatFrame_OnEvent
ChatFrame_OnEvent = function()
	if event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_SAY" or event == "CHAT_MSG_YELL" or event == "CHAT_MSG_BATTLEGROUND" or event == "CHAT_MSG_BATTLEGROUND_LEADER" or event == "CHAT_MSG_EMOTE" then
		arg1 = filter(arg1)
	end
	if arg1 ~= "" then
		return orig(event)
	end
end
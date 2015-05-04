--[[

Copyright (c) 2015 gameboxcloud.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local Event = class("Event")

local EXPORTED_METHODS = {
    "addEventListener",
    "dispatchEvent",
    "removeEventListener",
    "removeEventListenersByTag",
    "removeEventListenersByEvent",
    "removeAllEventListeners",
    "hasEventListener",
    "dumpAllEventListeners",
}

function Event:init_()
    self.target_ = nil
    self.listeners_ = {}
    self.nextListenerHandleIndex_ = 0
end

function Event:bind(target)
    self:init_()
    cc.setmethods(target, self, EXPORTED_METHODS)
    self.target_ = target
end

function Event:unbind(target)
    cc.unsetmethods(target, EXPORTED_METHODS)
    self:init_()
end

function Event:on(eventName, listener, tag)
    assert(type(eventName) == "string" and eventName ~= "",
        "Event:addEventListener() - invalid eventName")
    eventName = string.upper(eventName)
    if self.listeners_[eventName] == nil then
        self.listeners_[eventName] = {}
    end

    self.nextListenerHandleIndex_ = self.nextListenerHandleIndex_ + 1
    local handle = tostring(self.nextListenerHandleIndex_)
    tag = tag or ""
    self.listeners_[eventName][handle] = {listener, tag}

    if DEBUG > 1 then
        printInfo("%s [Event] addEventListener() - event: %s, handle: %s, tag: \"%s\"",
                  tostring(self.target_), eventName, handle, tostring(tag))
    end

    return self.target_, handle
end

Event.addEventListener = Event.on

function Event:dispatchEvent(event)
    event.name = string.upper(tostring(event.name))
    local eventName = event.name
    if DEBUG > 1 then
        printInfo("%s [Event] dispatchEvent() - event %s", tostring(self.target_), eventName)
    end

    if self.listeners_[eventName] == nil then return end
    event.target = self.target_
    event.stop_ = false
    event.stop = function(self)
        self.stop_ = true
    end

    for handle, listener in pairs(self.listeners_[eventName]) do
        if DEBUG > 1 then
            printInfo("%s [Event] dispatchEvent() - dispatching event %s to listener %s", tostring(self.target_), eventName, handle)
        end
        -- listener[1] = listener
        -- listener[2] = tag
        event.tag = listener[2]
        listener[1](event)
        if event.stop_ then
            if DEBUG > 1 then
                printInfo("%s [Event] dispatchEvent() - break dispatching for event %s", tostring(self.target_), eventName)
            end
            break
        end
    end

    return self.target_
end

function Event:removeEventListener(handleToRemove)
    for eventName, listenersForEvent in pairs(self.listeners_) do
        for handle, _ in pairs(listenersForEvent) do
            if handle == handleToRemove then
                listenersForEvent[handle] = nil
                if DEBUG > 1 then
                    printInfo("%s [Event] removeEventListener() - remove listener [%s] for event %s", tostring(self.target_), handle, eventName)
                end
                return self.target_
            end
        end
    end

    return self.target_
end

function Event:removeEventListenersByTag(tagToRemove)
    for eventName, listenersForEvent in pairs(self.listeners_) do
        for handle, listener in pairs(listenersForEvent) do
            -- listener[1] = listener
            -- listener[2] = tag
            if listener[2] == tagToRemove then
                listenersForEvent[handle] = nil
                if DEBUG > 1 then
                    printInfo("%s [Event] removeEventListener() - remove listener [%s] for event %s", tostring(self.target_), handle, eventName)
                end
            end
        end
    end

    return self.target_
end

function Event:removeEventListenersByEvent(eventName)
    self.listeners_[string.upper(eventName)] = nil
    if DEBUG > 1 then
        printInfo("%s [Event] removeAllEventListenersForEvent() - remove all listeners for event %s", tostring(self.target_), eventName)
    end
    return self.target_
end

function Event:removeAllEventListeners()
    self.listeners_ = {}
    if DEBUG > 1 then
        printInfo("%s [Event] removeAllEventListeners() - remove all listeners", tostring(self.target_))
    end
    return self.target_
end

function Event:hasEventListener(eventName)
    eventName = string.upper(tostring(eventName))
    local t = self.listeners_[eventName]
    for _, __ in pairs(t) do
        return true
    end
    return false
end

function Event:dumpAllEventListeners()
    print("---- Event:dumpAllEventListeners() ----")
    for name, listeners in pairs(self.listeners_) do
        printf("-- event: %s", name)
        for handle, listener in pairs(listeners) do
            printf("--     listener: %s, handle: %s", tostring(listener[1]), tostring(handle))
        end
    end
    return self.target_
end

return Event

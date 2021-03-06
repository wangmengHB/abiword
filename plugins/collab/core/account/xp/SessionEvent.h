/* Copyright (C) 2006 by Marc Maurer <uwog@uwog.net>
 * Copyright (C) 2007 One Laptop Per Child
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301 USA.
 */

#ifndef __SESSIONEVENT_H__
#define __SESSIONEVENT_H__

#include "Event.h"
#include <session/xp/AbiCollab.h>
#include <packet/xp/AbiCollab_Packet.h>

class StartSessionEvent : public Event
{
public:
	DECLARE_PACKET(StartSessionEvent);
};

class GetSessionsEvent : public Event
{
public:
	DECLARE_PACKET(GetSessionsEvent);
};

class GetSessionsResponseEvent : public Event
{
public:
	DECLARE_PACKET(GetSessionsResponseEvent);
	std::map<std::string,UT_UTF8String> m_Sessions;	// contains session/name pairs
};

class JoinSessionEvent : public Event
{
public:
	DECLARE_PACKET(JoinSessionEvent);
	JoinSessionEvent() : m_sSessionId("") {}
	JoinSessionEvent(const std::string& sessionId)
		: m_sSessionId(sessionId)
	{
		UT_ASSERT(m_sSessionId != "");
	}

	virtual std::string	toStr() const;

	const std::string&		getSessionId() const
		{ return m_sSessionId; }

private:
	std::string				m_sSessionId;
};

class JoinSessionRequestEvent : public JoinSessionEvent {
public:
	DECLARE_PACKET(JoinSessionRequestEvent);
	JoinSessionRequestEvent() {}
	JoinSessionRequestEvent(const std::string& sessionId)
	: JoinSessionEvent(sessionId) {}
};

class JoinSessionRequestResponseEvent : public Event
{
public:
	DECLARE_PACKET(JoinSessionRequestResponseEvent);
	JoinSessionRequestResponseEvent() : m_sDocumentName(""), m_sDocumentId(""), m_sSessionId(""), m_iAuthorId(-1) {}
	JoinSessionRequestResponseEvent(const std::string& sessionId, UT_sint32 iAuthorId)
		: m_iRev(0)
		, m_sDocumentName("")
		, m_sDocumentId("")
		, m_sSessionId(sessionId)
		, m_iAuthorId(iAuthorId)
	{
		UT_ASSERT(m_sSessionId != "");
	}

	const std::string&		getSessionId() const
		{ return m_sSessionId; }

	UT_sint32					getAuthorId() const
		{ return m_iAuthorId; }

	virtual std::string	toStr() const;

	std::string					m_sZABW;
	UT_sint32					m_iRev;
	UT_UTF8String				m_sDocumentName;
	std::string				m_sDocumentId;

private:
	std::string				m_sSessionId;
	UT_sint32					m_iAuthorId;
};

class DisjoinSessionEvent : public Event
{
public:
	DECLARE_PACKET(DisjoinSessionEvent);
	DisjoinSessionEvent() : m_sSessionId("") {}
	DisjoinSessionEvent(const std::string& sessionId)
		: m_sSessionId(sessionId)
	{
		UT_ASSERT(m_sSessionId != "");
	}

	virtual std::string	toStr() const;

	const std::string&		getSessionId() const
		{ return m_sSessionId; }

private:
	std::string				m_sSessionId;
};

class CloseSessionEvent : public Event
{
public:
	DECLARE_PACKET(CloseSessionEvent);
	CloseSessionEvent() : m_sSessionId("") {}
	CloseSessionEvent(const std::string& sessionId)
		: m_sSessionId(sessionId)
	{
		UT_ASSERT(m_sSessionId != "");
	}

	virtual std::string	toStr() const;

	const std::string&		getSessionId() const
		{ return m_sSessionId; }

private:
	std::string				m_sSessionId;
};

#endif /* __SESSIONEVENT_H__ */

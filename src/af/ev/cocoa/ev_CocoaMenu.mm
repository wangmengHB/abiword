/* -*- mode: C++; tab-width: 4; c-basic-offset: 4; -*- */
/* AbiSource Program Utilities
 * Copyright (C) 1998-2000 AbiSource, Inc.
 * Copyright (C) 2001-2004 Hubert Figuiere
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  
 * 02111-1307, USA.
 */


#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "ut_types.h"
#include "ut_stack.h"
#include "ut_string.h"
#include "ut_string_class.h"
#include "ut_debugmsg.h"
#include "xap_Types.h"
#include "ev_CocoaMenu.h"
#include "ev_CocoaMenuBar.h"
#include "ev_CocoaMenuPopup.h"
#include "xap_CocoaApp.h"
#include "xap_CocoaFrame.h"
#include "xap_CocoaDialog_Utilities.h"
#include "ev_CocoaKeyboard.h"
#include "ev_Menu_Layouts.h"
#include "ev_Menu_Actions.h"
#include "ev_Menu_Labels.h"
#include "ev_EditEventMapper.h"
#include "ut_string_class.h"
#include "ap_Menu_Id.h"
#include "ap_CocoaFrame.h"
#import "xap_CocoaFrameImpl.h"

#import <Cocoa/Cocoa.h>



@implementation EV_NSMenu

-(void)dealloc
{
	[_virtualItems release];
	[super dealloc];
}


-(id)initWithXAP:(EV_CocoaMenu*)owner andTitle:(NSString*)title
{
	self = [super initWithTitle:title];
	_virtualItems = [[NSMutableArray alloc] init];
	_xap = owner;
	return self;
}

// NSMenu overrides

-(void)update
{
	xxx_UT_DEBUGMSG(("-[EV_NSMenu update: %s]\n", [[self title] UTF8String]));
	_xap->_refreshMenu(self);
	[super update];
}

- (void)addVirtualItem:(id <NSMenuItem>)newItem
{
	[_virtualItems addObject:newItem];
}


- (NSEnumerator*)virtualItemsEnumerator
{
	return [_virtualItems objectEnumerator];
}

@end


@implementation EV_CocoaMenuTarget

- (void)setXAPOwner:(EV_CocoaMenu*)owner
{
	_xap = owner;
}


- (id)menuSelected:(id)sender
{
	UT_DEBUGMSG (("@EV_CocoaMenuTarget (id)menuSelected:(id)sender\n"));

	UT_ASSERT ([sender isKindOfClass:[NSMenuItem class]]);
	_xap->menuEvent([sender tag]);
	return sender;
}

@end


void
EV_CocoaMenu::_refreshMenu(EV_NSMenu *menu)
{
	XAP_App* app = XAP_App::getApp();
	AV_View* pView;
	XAP_Frame* frame = app->getLastFocussedFrame();
	if (frame) {
		pView = frame->getCurrentView();
	}
	else {
		pView = NULL;
	}
	const EV_Menu_ActionSet * pMenuActionSet = app->getMenuActionSet();
	const EV_EditMethodContainer * pEMC = app->getEditMethodContainer();
	UT_ASSERT(pEMC);
	
	NSMenuItem *menuItem;
	NSEnumerator * enumerator = [[menu itemArray] objectEnumerator];
	while (menuItem = [enumerator nextObject]) {
		[menu removeItem:menuItem];
	}
	
	enumerator = [menu virtualItemsEnumerator];
	
	while (menuItem = [enumerator nextObject]) {
		XAP_Menu_Id cmd = [menuItem tag];
		
		const EV_Menu_Action * pAction = pMenuActionSet->getAction(cmd);
		const EV_Menu_Label * pLabel = m_pMenuLabelSet->getLabel(cmd);
		EV_Menu_LayoutItem * pLayoutItem = m_pMenuLayout->getLayoutItem(m_pMenuLayout->getLayoutIndex(cmd));
		
		switch (pLayoutItem->getMenuLayoutFlags()) {
		case EV_MLF_Normal:
		{			
			// see if we need to enable/disable and/or check/uncheck it.
			bool bEnable = true;
			bool bCheck = false;
			
			if (pAction->hasGetStateFunction())
			{
				if (pView) {
					EV_Menu_ItemState mis = pAction->getMenuItemState(pView);
					if (mis & EV_MIS_Gray)
						bEnable = false;
					if (mis & EV_MIS_Toggled)
						bCheck = true;
				}
				else {
					bEnable = false;
					bCheck = false;				
				}
			}
			else {
				// TODO FIXME: store this somewhere
				const char *methodName = pAction->getMethodName();

				EV_EditMethod * pEM = pEMC->findEditMethodByName(methodName);
				if (pEM) {
					EV_EditMethodType t = pEM->getType();
					if (!(t & EV_EMT_APP_METHOD)) {
						bEnable = (pView != NULL);
					}
					else {
						bEnable = true;
					}
				}
				else {
					bEnable = false;
				}
			}

			// Get the dynamic label
			const char ** data = getLabelName(app, pAction, pLabel);
			const char * szLabelName = data[0];
			const char * szMnemonicName = data[1];		
			bool bHasDynamicLabel = pAction->hasDynamicLabel();
			
			/* 
			 we need to set the memnomic if current is empty even if it is not dynamic. Because we
			 may be running the first update after building the menu bar in the application without
			 having a frame. No frame = no shortcut actuallly because event mapper is tied to the frame.
			*/
			if (szMnemonicName && *szMnemonicName 
						&& (bHasDynamicLabel || [[menuItem keyEquivalent] isEqualToString:@""])) {
				NSString* shortCut;
				unsigned int modifier = 0;
				UT_DEBUGMSG(("changing menu shortcut\n"));
				shortCut = _getItemCmd (szMnemonicName, modifier);
				[menuItem setKeyEquivalent:shortCut];
			}

			// No dynamic label, check/enable
			if (!bHasDynamicLabel)
			{
				[menu addItem:menuItem];
			}
			else {
				szLabelName = pAction->getDynamicLabel(pLabel);
				if (szLabelName && *szLabelName) {
					char buf[1024];
					_convertLabelToMac(buf, sizeof (buf), szLabelName);
					[menuItem setTitle:[NSString stringWithUTF8String:buf]];
					[menu addItem:menuItem];
				}
			}
			
			[menuItem setState:(bCheck?NSOnState:NSOffState)];
			[menuItem setEnabled:(bEnable?YES:NO)];
			break;
		}
		case EV_MLF_Separator:
			[menu addItem:menuItem];
			break;

		case EV_MLF_BeginSubMenu:
		{
			bool bEnable = (pView != NULL);
			if (pAction->hasGetStateFunction())
			{
				if (pView) {
					EV_Menu_ItemState mis = pAction->getMenuItemState(pView);
					if (mis & EV_MIS_Gray) {
						bEnable = false;
					}
				}
				else {
					bEnable = false;
				}
			}
			[menu addItem:menuItem];
			[menuItem setEnabled:(bEnable?YES:NO)];
			break;
		}
		case EV_MLF_EndSubMenu:
		case EV_MLF_BeginPopupMenu:
		case EV_MLF_EndPopupMenu:
			break;
			
		default:
			UT_ASSERT_NOT_REACHED();
			break;
		}
	}
}


/*****************************************************************/


EV_CocoaMenu::EV_CocoaMenu(XAP_CocoaApp * pCocoaApp,
						 const char * szMenuLayoutName,
						 const char * szMenuLabelSetName)
	: EV_Menu(pCocoaApp, pCocoaApp->getEditMethodContainer(), szMenuLayoutName, szMenuLabelSetName),
	  m_pCocoaApp(pCocoaApp)
{
	m_menuTarget = [[EV_CocoaMenuTarget alloc] init];
	[m_menuTarget setXAPOwner:this];
}

EV_CocoaMenu::~EV_CocoaMenu()
{
	[m_menuTarget release];
}

bool EV_CocoaMenu::menuEvent(XAP_Menu_Id menuid)
{
	// user selected something from the menu.
	// invoke the appropriate function.
	// return true if handled.

	const EV_Menu_ActionSet * pMenuActionSet = m_pCocoaApp->getMenuActionSet();
	UT_ASSERT(pMenuActionSet);

	const EV_Menu_Action * pAction = pMenuActionSet->getAction(menuid);
	UT_ASSERT(pAction);

	const char * szMethodName = pAction->getMethodName();
	if (!szMethodName)
		return false;
	
	const EV_EditMethodContainer * pEMC = m_pCocoaApp->getEditMethodContainer();
	UT_ASSERT(pEMC);

	EV_EditMethod * pEM = pEMC->findEditMethodByName(szMethodName);
	UT_ASSERT(pEM);						// make sure it's bound to something

	UT_String script_name(pAction->getScriptName());
	XAP_Frame* frame = NULL;
	AV_View* view = NULL;
	frame = static_cast<XAP_CocoaApp*>(XAP_App::getApp())->_getFrontFrame();
	if (frame) {
		view =  frame->getCurrentView();
	}
	invokeMenuMethod(view, pEM, script_name);
	return true;
}


bool EV_CocoaMenu::synthesizeMenu(NSMenu * wMenuRoot)
{
	UT_DEBUGMSG(("EV_CocoaMenu::synthesizeMenu\n"));
	const EV_Menu_ActionSet * pMenuActionSet = m_pCocoaApp->getMenuActionSet();
	UT_ASSERT(pMenuActionSet);
	
	UT_uint32 nrLabelItemsInLayout = m_pMenuLayout->getLayoutItemCount();
	UT_ASSERT(nrLabelItemsInLayout > 0);

	// we keep a stack of the widgets so that we can properly
	// parent the menu items and deal with nested pull-rights.
	bool bResult;
	UT_Stack stack;
	stack.push(wMenuRoot);

	for (UT_uint32 k = 0; (k < nrLabelItemsInLayout); k++)
	{
		EV_Menu_LayoutItem * pLayoutItem = m_pMenuLayout->getLayoutItem(k);
		UT_ASSERT(pLayoutItem);
		
		XAP_Menu_Id menuid = pLayoutItem->getMenuId();
		// VERY BAD HACK!  It will be here until I fix the const correctness of all the functions
		// using EV_Menu_Action
		const EV_Menu_Action * pAction = pMenuActionSet->getAction(menuid);
		UT_ASSERT(pAction);
		const EV_Menu_Label * pLabel = m_pMenuLabelSet->getLabel(menuid);
		UT_ASSERT(pLabel);

		// get the name for the menu item
		const char * szLabelName;
		const char * szMnemonicName;
		
		switch (pLayoutItem->getMenuLayoutFlags())
		{
		case EV_MLF_Normal:
		{
			unsigned int modifier = 0;
			const char ** data = getLabelName(m_pCocoaApp, pAction, pLabel);
			szLabelName = data[0];
			szMnemonicName = data[1];
			
			NSString * shortCut = nil;
			
			if (data[1] && *(data[1])) {
				shortCut = _getItemCmd (data[1], modifier);
			}
			else {
				shortCut = [NSString string];
			}
			char buf[1024];
			// convert label into underscored version

			// create the item with the underscored label
			EV_NSMenu * wParent;
			bResult = stack.viewTop((void **)&wParent);
			UT_ASSERT(bResult);

			NSMenuItem * menuItem = nil;
			NSString * str = nil;
			if (szLabelName) {
				_convertLabelToMac(buf, sizeof (buf), szLabelName);
				str = [[NSString alloc] initWithUTF8String:buf];
			}
			else {
				str = [[NSString alloc] init];
			}
			switch (menuid) {
			
			case AP_MENU_ID_HELP_ABOUT:
				menuItem = [XAP_AppController_Instance _aboutMenu];
				[menuItem setTitle:str];
				[menuItem setKeyEquivalent:shortCut];
				break;
			case AP_MENU_ID_TOOLS_OPTIONS:
				menuItem = [XAP_AppController_Instance _preferenceMenu];
				[menuItem setTitle:str];
				[menuItem setKeyEquivalent:shortCut];
				break;
			case AP_MENU_ID_FILE_EXIT:
				menuItem = [XAP_AppController_Instance _quitMenu];
				[menuItem setTitle:str];
				[menuItem setKeyEquivalent:shortCut];					
				break;
			default:
				menuItem = [[NSMenuItem alloc] initWithTitle:str action:nil
								keyEquivalent:shortCut];
				[wParent addVirtualItem:menuItem];
				[menuItem release];
			}
			[menuItem setTarget:m_menuTarget];
			[menuItem setAction:@selector(menuSelected:)];
			[menuItem setTag:pLayoutItem->getMenuId()];
			[str release];
			break;
		}
		case EV_MLF_BeginSubMenu:
		{
			const char ** data = getLabelName(m_pCocoaApp, pAction, pLabel);
			szLabelName = data[0];
			
			char buf[1024];
			// convert label into underscored version
			// create the item with the underscored label
			EV_NSMenu * wParent;
			bResult = stack.viewTop((void **)&wParent);
			UT_ASSERT(bResult);

			NSMenuItem * menuItem = nil;
			NSString * str = nil;
			if (szLabelName) {
				_convertLabelToMac(buf, sizeof (buf), szLabelName);
				str = [NSString stringWithUTF8String:buf];	
			}
			else {
				str = [NSString string]; // autoreleased
			}
			if ([wParent isKindOfClass:[EV_NSMenu class]]) {
				menuItem = [[NSMenuItem alloc] initWithTitle:str action:nil keyEquivalent:@""];
				[wParent addVirtualItem:menuItem];
				[menuItem release];
			}
			else {
				menuItem = [wParent addItemWithTitle:str action:nil keyEquivalent:@""];
			}
			
			// item is created, add to class vector
			[menuItem setTag:(int)pLayoutItem->getMenuId()];

			EV_NSMenu * subMenu = [[EV_NSMenu alloc] initWithXAP:this andTitle:str];
			[menuItem setSubmenu:subMenu];
			[subMenu setAutoenablesItems:NO];
			[subMenu release];
			stack.push((void **)subMenu);
			break;
		}
		case EV_MLF_EndSubMenu:
		{
			// pop and inspect
			EV_NSMenu * menu;
			bResult = stack.pop((void **)&menu);
			UT_ASSERT(bResult);

			break;
		}
		case EV_MLF_Separator:
		{	
			NSMenuItem * menuItem = nil;
			menuItem = [NSMenuItem separatorItem];

			EV_NSMenu * wParent;
			bResult = stack.viewTop((void **)&wParent);
			UT_ASSERT(bResult);
			[wParent addVirtualItem:menuItem];

			[menuItem setTag:(int)pLayoutItem->getMenuId()];
			break;
		}

		case EV_MLF_BeginPopupMenu:
		case EV_MLF_EndPopupMenu:
			break;
			
		default:
			UT_ASSERT_NOT_REACHED();
			break;
		}
	}

	// make sure our last item on the stack is the one we started with
	EV_NSMenu * wDbg = NULL;
	bResult = stack.pop((void **)&wDbg);
	UT_ASSERT(bResult);
	UT_ASSERT(wDbg == wMenuRoot);

	return true;
}


bool EV_CocoaMenu::_doAddMenuItem(UT_uint32 layout_pos)
{	
	UT_ASSERT_NOT_REACHED();
	return false;
}


/*!
	Return the menu shortcut for the mnemonic
	
	\param mnemonic the string for the menmonic
	\returnvalue modifier the modifiers
	\return newly allocated NSString that contains the key equivalent. 
	should be nil on entry.
 */
NSString* EV_CocoaMenu::_getItemCmd (const char * mnemonic, unsigned int & modifiers)
{
	bool needsShift = false;
	modifiers = 0;
	char * p;
	if (strstr (mnemonic, "Alt+")) {
		modifiers |= NSAlternateKeyMask;
	}
	if (strstr (mnemonic, "Ctrl+") != NULL) {
		modifiers |= NSCommandKeyMask;
	}
	if (strstr (mnemonic, "Shift+") != NULL) {
		needsShift = true;
	}
	if ((modifiers & NSCommandKeyMask) == 0) {
		p = (char *)mnemonic;
	}
	else {
		p = strrchr (mnemonic, '+');
		p++;
	}

	NSString *shortcut = nil;
	if ((p[1] == 0) && needsShift) {
		shortcut = [[NSString stringWithUTF8String:p] uppercaseString];
	}
	else {
		shortcut = [NSString stringWithUTF8String:p];
	}
	xxx_UT_DEBUGMSG(("returning shortcut %s\n", [shortcut UTF8String]));
	return shortcut;
}


/*****************************************************************/

EV_CocoaMenuBar::EV_CocoaMenuBar(XAP_CocoaApp * pCocoaApp,
							   const char * szMenuLayoutName,
							   const char * szMenuLabelSetName)
	: EV_CocoaMenu(pCocoaApp, szMenuLayoutName, szMenuLabelSetName)
{
}

EV_CocoaMenuBar::~EV_CocoaMenuBar()
{
}

void  EV_CocoaMenuBar::destroy(void)
{
}

bool EV_CocoaMenuBar::synthesizeMenuBar(NSMenu *menu)
{
	// Just create, don't show the menu bar yet.  It is later added
	// to a 3D handle box and shown
	m_wMenuBar = menu;

	synthesizeMenu(m_wMenuBar);
	
	[NSApp setMainMenu:m_wMenuBar];
	return true;
}


bool EV_CocoaMenuBar::rebuildMenuBar()
{
	UT_ASSERT (UT_NOT_IMPLEMENTED);
	return false;
}

bool EV_CocoaMenuBar::refreshMenu(AV_View * pView)
{
	return true;
}

/*****************************************************************/

EV_CocoaMenuPopup::EV_CocoaMenuPopup(XAP_CocoaApp * pCocoaApp,
								   const char * szMenuLayoutName,
								   const char * szMenuLabelSetName)
	: EV_CocoaMenu(pCocoaApp, szMenuLayoutName, szMenuLabelSetName),
		m_wMenuPopup(nil)
{
}

EV_CocoaMenuPopup::~EV_CocoaMenuPopup()
{
	[m_wMenuPopup release];
}

NSMenu * EV_CocoaMenuPopup::getMenuHandle() const
{
	return m_wMenuPopup;
}

bool EV_CocoaMenuPopup::synthesizeMenuPopup()
{
	m_wMenuPopup = [[NSMenu alloc] initWithTitle:@""];
	[m_wMenuPopup setAutoenablesItems:NO];
	synthesizeMenu(m_wMenuPopup);
	return true;
}

bool EV_CocoaMenuPopup::refreshMenu(AV_View * pView)
{
	return true;
}

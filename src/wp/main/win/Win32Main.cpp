/* AbiWord
 * Copyright (C) 1998 AbiSource, Inc.
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


#include <windows.h>
#include <crtdbg.h>
#include <string.h>

#ifdef ABI_OPT_JS
#include <js.h>
#endif /* ABI_OPT_JS */

#include "ap_Win32App.h"
#include "ap_Win32Frame.h"

#ifdef   _DEBUG
#define  SET_CRT_DEBUG_FIELD(a) \
            _CrtSetDbgFlag((a) | _CrtSetDbgFlag(_CRTDBG_REPORT_FLAG))
#define  CLEAR_CRT_DEBUG_FIELD(a) \
            _CrtSetDbgFlag(~(a) & _CrtSetDbgFlag(_CRTDBG_REPORT_FLAG))
#else
#define  SET_CRT_DEBUG_FIELD(a)   ((void) 0)
#define  CLEAR_CRT_DEBUG_FIELD(a) ((void) 0)
#endif

int WINAPI WinMain (HINSTANCE hInstance, HINSTANCE hPrevInstance,
                    PSTR szCmdLine, int iCmdShow)
{
	static char szAppName[] = "Abi" ;
	HWND        hwnd ;
	MSG         msg ;

	// TODO the following two variables are a temporary hack.
	// TODO we need to convert szCmdLine into argc/argv format.
	int argc = 0;
	char ** argv = NULL;

	_CrtSetReportMode( _CRT_WARN, _CRTDBG_MODE_DEBUG );
	_CrtSetReportMode( _CRT_ERROR, _CRTDBG_MODE_DEBUG );
	_CrtSetReportMode( _CRT_ASSERT, _CRTDBG_MODE_DEBUG );

	// initialize our application.

	AP_Win32App * pMyWin32App = new AP_Win32App(hInstance);
	pMyWin32App->initialize(&argc,&argv);

	// create the first window.

	AP_Win32Frame * pFirstWin32Frame = new AP_Win32Frame(pMyWin32App);
	pFirstWin32Frame->initialize(&argc,&argv);
	hwnd = pFirstWin32Frame->getTopLevelWindow();
	
	{
		// Yuck!  strtok is a horrible way to do this
		char*	p = strdup(szCmdLine);
		char*	q = strtok(p, " ");

		/*
		  Yuck!  This command-line parsing loop is horrible.
		  It's a barely-functional hack which allows us to pass
		  a script using -script on the command line.  Replace
		  this ugliness.
		*/
		while (q)
		{
#ifdef ABI_OPT_JS			
			if (0 == strcmp(q, "-script"))
			{
				q = strtok(NULL, " ");
				js_eval_file(pMyWin32App->getInterp(), q);
				
				q = strtok(NULL, " ");
			}
			else
#endif /* ABI_OPT_JS */
			{
				break;
			}
		}
		
		pFirstWin32Frame->loadDocument(q);

		free(p);
	}
	

	ShowWindow (hwnd, iCmdShow) ;
	UpdateWindow (hwnd) ;

	// turn over control to windows

	while (GetMessage (&msg, NULL, 0, 0))
	{
//		TranslateMessage (&msg) ;
		DispatchMessage (&msg) ;
	}

	// destroy the App.  It should take care of deleting all frames.

	delete pMyWin32App;

	SET_CRT_DEBUG_FIELD( _CRTDBG_LEAK_CHECK_DF );

	return msg.wParam ;
}

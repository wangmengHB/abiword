/* AbiSource Application Framework
 * Copyright (C) 1998 AbiSource, Inc.
 * Copyright (C) 2001 Hubert Figuiere
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

#ifndef XAP_COCOATOOLBARICONS_H
#define XAP_COCOATOOLBARICONS_H

#import <Cocoa/Cocoa.h>

#include "ut_types.h"

#include "xap_Toolbar_Icons.h"

/*****************************************************************/

@interface XAP_CocoaToolbarButton : NSButton
{
}
- (void)drawRect:(NSRect)aRect;
@end

class AP_CocoaToolbar_Icons : public AP_Toolbar_Icons
{
public:
	AP_CocoaToolbar_Icons(void);
	~AP_CocoaToolbar_Icons(void);

	NSImage*			getPixmapForIcon(const char * szIconName);
	
protected:
};

#endif /* XAP_COCOATOOLBARICONS_H */

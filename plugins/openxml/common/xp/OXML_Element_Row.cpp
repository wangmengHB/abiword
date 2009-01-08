/* -*- mode: C++; tab-width: 4; c-basic-offset: 4; -*- */

/* AbiSource
 * 
 * Copyright (C) 2008 Firat Kiyak <firatkiyak@gmail.com>
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

// Class definition include
#include <OXML_Element_Row.h>

// AbiWord includes
#include <ut_types.h>
#include <ut_string.h>
#include <pd_Document.h>

OXML_Element_Row::OXML_Element_Row(std::string id, OXML_Element_Table* tbl) : 
	OXML_Element(id, TR_TAG, ROW), numCols(0), table(tbl)
{	
}

OXML_Element_Row::~OXML_Element_Row()
{

}

UT_Error OXML_Element_Row::serialize(IE_Exp_OpenXML* exporter)
{
	UT_Error err = UT_OK;

	err = exporter->startRow();
	if(err != UT_OK)
		return err;

	err = this->serializeProperties(exporter);
	if(err != UT_OK)
		return err;

	err = this->serializeChildren(exporter);
	if(err != UT_OK)
		return err;

	return exporter->finishRow();
}

UT_Error OXML_Element_Row::serializeChildren(IE_Exp_OpenXML* exporter)
{
	UT_Error ret = UT_OK;
	
	OXML_ElementVector children = getChildren();
	
	UT_sint32 left = 0; 
	OXML_Element_Cell* cell = NULL;

	//during the loop check to see if we are missing any cells due to vertical merging
	//if so let's add them manually
	OXML_ElementVector::size_type i;
	for(i=0; i < children.size(); i++)
	{
		cell = static_cast<OXML_Element_Cell*>(get_pointer(children[i]));
		
		for(; left < cell->getLeft(); left++){
			//top=-1,bottom=0 means vertically continued cell
			OXML_Element_Cell temp("", table, left, left+1, -1, 0); 
			OXML_SharedElement shared_paragraph(new OXML_Element_Paragraph(""));

			ret = temp.appendElement(shared_paragraph);
			if(ret != UT_OK)
				return ret;			

			ret = temp.serialize(exporter);
			if(ret != UT_OK)
				return ret;			
		}

		left = cell->getRight();

		ret = cell->serialize(exporter);
		if(ret != UT_OK)
			return ret;
	}

	//right most vertically merged cells
	for(; left < numCols; left++){
		OXML_Element_Cell temp("", table, left, left+1, -1, 0); 
		OXML_SharedElement shared_paragraph(new OXML_Element_Paragraph(""));

		ret = temp.appendElement(shared_paragraph);
		if(ret != UT_OK)
			return ret;			

		ret = temp.serialize(exporter);
		if(ret != UT_OK)
			return ret;
	}

	return ret;
}


UT_Error OXML_Element_Row::serializeProperties(IE_Exp_OpenXML* /*exporter*/)
{
	//TODO
	return UT_OK;
}


UT_Error OXML_Element_Row::addToPT(PD_Document * /*pDocument*/)
{
	//TODO
	return UT_OK;
}

void OXML_Element_Row::setNumCols(UT_sint32 columns)
{
	numCols = columns;	
}
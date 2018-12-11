// smartreader.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "smartreader.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif

// The one and only application object

CWinApp theApp;

//using namespace std;
using namespace tinyxml2;

int _tmain(int argc, TCHAR* argv[], TCHAR* envp[])
{
	CSmartReader m_oSmartReader;
	ST_DRIVE_INFO *pDriveInfo = NULL;
	BYTE ucT1, ucT2;
	ST_SMART_INFO *pSmartInfo = NULL;
	ST_SMART_DETAILS *pSmartDetails = NULL;
	ST_IDSECTOR *pSectorInfo = NULL;

	if (!AfxWinInit(::GetModuleHandle(NULL), NULL, ::GetCommandLine(), 0))
	{
		// TODO: change error code to suit your needs
		_tprintf(_T("Fatal Error: MFC initialization failed\n"));
		return -1;
	}

	printf("Storages SMART information retriever v1.0 by dUkk\r\n");

	if (argc < 2)
	{
		printf("usage: %s <output.xml>\r\n", argv[0]);
		return -2;
	}

	char szINIFileName[MAX_PATH] = { 0 };
	GetModuleFileName(NULL, szINIFileName, MAX_PATH);
	szINIFileName[lstrlen(szINIFileName) - 3] = 0;
	lstrcat(szINIFileName, "ini");
	if (!PathFileExistsA(szINIFileName))
	{
		printf("can't open %s\r\n", szINIFileName);
		return -3;
	}

	tinyxml2::XMLDocument mdoc;
	XMLNode *Root;
	const char* ConfTemplate =
		"<?xml version=\"1.0\" encoding=\"windows-1251\" ?>\n"
		"<smart>\n"
		"</smart>";
	mdoc.Parse(ConfTemplate);
	Root = mdoc.RootElement();

	m_oSmartReader.ReadSMARTValuesForAllDrives();

	for (ucT1 = 0; ucT1 < m_oSmartReader.m_ucDrivesWithInfo; ++ucT1)
	{
		XMLElement *item1 = mdoc.NewElement("drive");
		pSectorInfo = &m_oSmartReader.m_stDrivesInfo[ucT1].m_stInfo;
		item1->SetAttribute("id", ucT1);
		item1->SetAttribute("model", (PCHAR)pSectorInfo->sModelNumber);
		item1->SetAttribute("serial", (PCHAR)pSectorInfo->sSerialNumber);
		XMLNode *subNode = Root->InsertEndChild(item1);

		pDriveInfo = m_oSmartReader.GetDriveInfo(ucT1);
		for (ucT2 = 0; ucT2 < 255; ++ucT2)
		{
			pSmartInfo = m_oSmartReader.GetSMARTValue(pDriveInfo->m_ucDriveIndex, ucT2);
			if (pSmartInfo)
			{
				pSmartDetails = m_oSmartReader.GetSMARTDetails(pSmartInfo->m_ucAttribIndex);
				if (pSmartDetails)
				{
					XMLElement *item2 = mdoc.NewElement("attrib");
					item2->SetAttribute("id", (int)pSmartDetails->m_ucAttribId);
					item2->SetAttribute("name", pSmartDetails->m_csAttribName);
					item2->SetAttribute("value", (int)pSmartInfo->m_ucValue);
					item2->SetAttribute("worst", (int)pSmartInfo->m_ucWorst);
					item2->SetAttribute("raw", (int)pSmartInfo->m_dwAttribValue);
					item2->SetAttribute("treshold", (int)pSmartInfo->m_dwThreshold);
					subNode->InsertEndChild(item2);
				}
			}
		}

		mdoc.SaveFile(argv[1]);
	}

	return 0;
}

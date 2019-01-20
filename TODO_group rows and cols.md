# File
xl/worksheets/sheet1.xml

# group rows, 2, 3, 4
XPath: /worksheet/sheetFormatPr/@outlineLevelRow
```xml
<sheetFormatPr baseColWidth="12" defaultColWidth="8.83203125" defaultRowHeight="17" outlineLevelRow="1"/>
```

XPath: 
- /worksheet/sheetData/row[2]/@outlineLevel
- /worksheet/sheetData/row[3]/@outlineLevel
- /worksheet/sheetData/row[4]/@outlineLevel
```xml
<row r="2" spans="1:3" outlineLevel="1"><c r="A2"><v>1</v></c><c r="B2"><v>2</v></c><c r="C2"><v>93</v></c></row>
```

# group cols B, C, and then group col B
XPATH: /worksheet/cols
```xml
<cols>
    <col min="2" max="2" width="8.83203125" customWidth="1" outlineLevel="2"/>
    <col min="3" max="3" width="8.83203125" customWidth="1" outlineLevel="1"/>
</cols>
```

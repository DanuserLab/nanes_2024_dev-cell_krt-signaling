function items = bnGetSlidesetTableColumn(slideSetFileName, tableName, columnName)
%bnGetSlidesetTableColumn - Description
%
% Syntax: items = bnGetSlidesetTableColumn(slideSetFileName, tableName, columnName)
%
% slideSetFileName - File name of a Slide Set Table (xml)
% tableName - Name of the table containing the data of interest
% columnName - Name of the column containgin the data of interest
%
% Result:
% items - String array of the contents of the requested column
%
    D = xmlread(slideSetFileName);
    Ts = D.getElementsByTagName("SlideSet");
    for(iT = 1:Ts.getLength())
        T = Ts.item(iT-1);
        if(string(T.getAttribute("name")) ~= tableName)
            continue
        end
        Cs = T.getChildNodes();
        for(iC = 1:Cs.getLength())
            C = Cs.item(iC-1);
            Cn = string(C.getNodeName());
            if(Cn ~= 'col'), continue; end
            Ca = string(C.getAttribute("name"));
            if(Ca ~= columnName)
                continue
            end
            Es = C.getElementsByTagName("e");
            items = strings(1,Es.getLength());
            for(iE = 1:Es.getLength())
                E = Es.item(iE-1);
                items(iE) = E.getTextContent();
            end
            return
        end
    end
    items = [];
end
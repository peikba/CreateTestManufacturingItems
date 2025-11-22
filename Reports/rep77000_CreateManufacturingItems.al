report 77000 "BAC Create Manufacturing Item"
{
    Caption = 'Create Manufacturing Item';
    UsageCategory = Administration;
    ApplicationArea = All;
    ProcessingOnly = true;

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(OffSetItemNo; OffSetItemNo)
                    {
                        Caption = 'OffSet Item No';
                        ApplicationArea = All;
                    }
                    field(AddExtraItems; AddExtraItems)
                    {
                        Caption = 'Add Extra Items';
                        ApplicationArea = All;
                    }
                }
            }
        }
    }

    trigger OnInitReport()
    begin
        OffSetItemNo := 90000;
    end;

    trigger OnPreReport()
    var
        item: Record Item;
        CompanyInfo: Record "Company Information";
        WarningTxt: Label 'User Experience in %1 must be set to premium\Show Capacities in must be set to minutes in Manufacturing Setup\WIP Account must be set in Inventory Posting Setup';
    begin
        CompanyInfo.get();
        if not confirm(WarningTxt, false, CompanyInfo.TableCaption) then
            Exit;
        if Item.Get(Format(OffSetItemNo)) then
            if Confirm(ItemsExist) then
                DeleteItems;

        if not Confirm(AreYouSureTxt) then
            exit;

        CreateWorkCenter('100', 'Assembly', 1.2, '');
        CreateWorkCenter('300', 'Painting', 1.5, '');
        CreateWorkCenter('200', 'Machine', 1.3, '');
        CreateWorkCenter('400', 'Packing', 1.1, '');
        CreateItems;
        Message(DoneTxt, CreatedItems);
    end;

    var
        Item: Record Item;
        OffSetItemNo: Integer;
        AddExtraItems: Boolean;
        RawMatNo: Integer;
        FinishedTxt: Label 'Finished %1';
        SemiTxt: Label 'Subassembly %1';
        RawTxt: Label 'Raw Material %1';
        AreYouSureTxt: Label 'Create Test Items - Are you sure?';
        DoneTxt: Label 'The following items were created:\%1';
        CreatedItems: Text;
        lf: Char;
        ItemsExist: Label 'Items Exist already - delete test items?';

    local procedure CreateItems()
    var
        Item2: Record Item;
    begin
        lf := 10;
        Item2.SetRange("Costing Method", item2."Costing Method"::FIFO);
        Item2.FindFirst();
        CreateItem(Format(OffSetItemNo), Item2, FinishedTxt, Item."Replenishment System"::"Prod. Order", 0);
        CreatedItems := Item."No." + format(lf);
        CreateFinishedBom(Item);
        CreateRoutingHeaders(Item);

        OffSetItemNo += 1000;

        CreateItem(Format(OffSetItemNo), Item2, SemiTxt, Item."Replenishment System"::"Prod. Order", 0);
        CreatedItems += Item."No." + format(lf);

        CreateSemiBom(Item);
        CreateRoutingHeaders(Item);

        RawMatNo := 1;
        OffSetItemNo += 1000 + RawMatNo;
        CreateItem(Format(OffSetItemNo), Item2, StrSubstNo(RawTxt, RawMatNo), Item."Replenishment System"::Purchase, 10);
        CreatedItems += Item."No." + format(lf);

        RawMatNo += 1;
        OffSetItemNo += 1;
        CreateItem(Format(OffSetItemNo), Item2, StrSubstNo(RawTxt, RawMatNo), Item."Replenishment System"::Purchase, 11);
        CreatedItems += Item."No." + format(lf);

        RawMatNo += 1;
        OffSetItemNo += 1;
        CreateItem(Format(OffSetItemNo), Item2, StrSubstNo(RawTxt, RawMatNo), Item."Replenishment System"::Purchase, 12);
        CreatedItems += Item."No." + format(lf);

        if not AddExtraItems then
            exit;
        RawMatNo += 1;
        OffSetItemNo += 1;
        CreateItem(Format(OffSetItemNo), Item2, StrSubstNo(RawTxt, RawMatNo), Item."Replenishment System"::Purchase, 16);
        CreatedItems += Item."No." + format(lf);

        RawMatNo += 1;
        OffSetItemNo += 1;
        CreateItem(Format(OffSetItemNo), Item2, StrSubstNo(RawTxt, RawMatNo), Item."Replenishment System"::Purchase, 24);
        CreatedItems += Item."No." + format(lf);
    end;

    local procedure CreateFinishedBom(inItem: Record Item)
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
    begin
        ProdBOMHeader.Init;
        ProdBOMHeader."No." := inItem."No.";
        ProdBOMHeader.Description := StrSubstNo(FinishedTxt, ProdBOMHeader.TableCaption);
        ProdBOMHeader."Unit of Measure Code" := inItem."Base Unit of Measure";
        ProdBOMHeader.Insert;
        ProdBOMLine.Init;
        ProdBOMLine."Production BOM No." := ProdBOMHeader."No.";
        ProdBOMLine."Line No." := 10000;
        ProdBOMLine.Type := ProdBOMLine.Type::Item;
        ProdBOMLine."No." := Format(OffSetItemNo + 1000);
        ProdBOMLine.Description := StrSubstNo(SemiTxt, inItem.TableCaption);
        ProdBOMLine."Unit of Measure Code" := inItem."Base Unit of Measure";
        ProdBOMLine.Quantity := 1;
        ProdBOMLine."Quantity per" := 1;
        ProdBOMLine.Insert;

        ProdBOMLine.Init;
        ProdBOMLine."Production BOM No." := ProdBOMHeader."No.";
        ProdBOMLine."Line No." := 20000;
        ProdBOMLine.Type := ProdBOMLine.Type::Item;
        ProdBOMLine."No." := Format(OffSetItemNo + 2001);
        ProdBOMLine.Description := StrSubstNo(RawTxt, 1);
        ProdBOMLine."Unit of Measure Code" := inItem."Base Unit of Measure";
        ProdBOMLine.Quantity := 1;
        ProdBOMLine."Quantity per" := 1;
        ProdBOMLine.Insert;
    end;

    local procedure CreateSemiBom(inItem: Record Item)
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
    begin
        ProdBOMHeader.Init;
        ProdBOMHeader."No." := inItem."No.";
        ProdBOMHeader.Description := StrSubstNo(SemiTxt, ProdBOMHeader.TableCaption);
        ProdBOMHeader."Unit of Measure Code" := inItem."Base Unit of Measure";
        ProdBOMHeader.Insert;
        ProdBOMLine.Init;
        ProdBOMLine."Production BOM No." := ProdBOMHeader."No.";
        ProdBOMLine."Line No." := 10000;
        ProdBOMLine.Type := ProdBOMLine.Type::Item;
        ProdBOMLine."No." := Format(OffSetItemNo + 1002);
        ProdBOMLine.Description := StrSubstNo(RawTxt, 2);
        ProdBOMLine."Unit of Measure Code" := inItem."Base Unit of Measure";
        ProdBOMLine.Quantity := 1;
        ProdBOMLine."Quantity per" := 1;
        ProdBOMLine.Insert;

        ProdBOMLine.Init;
        ProdBOMLine."Production BOM No." := ProdBOMHeader."No.";
        ProdBOMLine."Line No." := 20000;
        ProdBOMLine.Type := ProdBOMLine.Type::Item;
        ProdBOMLine."No." := Format(OffSetItemNo + 1003);
        ProdBOMLine.Description := StrSubstNo(RawTxt, 3);
        ProdBOMLine."Unit of Measure Code" := inItem."Base Unit of Measure";
        ProdBOMLine.Quantity := 1;
        ProdBOMLine."Quantity per" := 1;
        ProdBOMLine.Insert;
    end;

    local procedure CreateRoutingHeaders(inItem: Record Item)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        RoutingHeader."No." := inItem."No.";
        case inItem."No." of
            Format(OffSetItemNo):
                RoutingHeader.Description := StrSubstNo(FinishedTxt, RoutingHeader.TableCaption);
            else
                RoutingHeader.Description := StrSubstNo(SemiTxt, RoutingHeader.TableCaption);
        end;
        RoutingHeader.Insert;
        RoutingLine.Init;
        RoutingLine."Routing No." := RoutingHeader."No.";
        RoutingLine.Validate("Operation No.", '010');
        RoutingLine.Validate(Type, RoutingLine.Type::"Work Center");
        RoutingLine.Validate("No.", '100');
        RoutingLine."Setup Time" := 10;
        RoutingLine."Run Time" := 10;
        RoutingLine.Insert;

        RoutingLine.Validate("Operation No.", '020');
        RoutingLine.Validate("No.", '300');
        RoutingLine.Insert;

        RoutingLine.Validate("Operation No.", '030');
        RoutingLine.Validate("No.", '200');
        RoutingLine.Insert;
    end;

    local procedure DeleteItems()
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        ProdBOMHeader: Record "Production BOM Header";
    begin

        if Item.Get(Format(OffSetItemNo)) then begin
            Item."Routing No." := '';
            Item."Production BOM No." := '';
            Item.Modify;
            Item.Delete(true);
        end;

        if RoutingHeader.Get(Format(OffSetItemNo)) then begin
            RoutingHeader.Status := RoutingHeader.Status::New;
            RoutingHeader.Modify;
            RoutingHeader.Delete(true);
        end;

        if ProdBOMHeader.Get(Format(OffSetItemNo)) then begin
            ProdBOMHeader.Status := ProdBOMHeader.Status::New;
            ProdBOMHeader.Modify;
            ProdBOMHeader.Delete(true);
        end;

        if Item.Get(Format(OffSetItemNo + 1000)) then begin
            Item."Routing No." := '';
            Item."Production BOM No." := '';
            Item.Modify;
            Item.Delete(true);
        end;

        if RoutingHeader.Get(Format(OffSetItemNo + 1000)) then begin
            RoutingHeader.Status := RoutingHeader.Status::New;
            RoutingHeader.Modify;
            RoutingHeader.Delete(true);
        end;

        if ProdBOMHeader.Get(Format(OffSetItemNo + 1000)) then begin
            ProdBOMHeader.Status := ProdBOMHeader.Status::New;
            ProdBOMHeader.Modify;
            ProdBOMHeader.Delete(true);
        end;

        if Item.Get(Format(OffSetItemNo + 2001)) then
            Item.Delete(true);

        if Item.Get(Format(OffSetItemNo + 2002)) then
            Item.Delete(true);

        if Item.Get(Format(OffSetItemNo + 2003)) then
            Item.Delete(true);
    end;

    local procedure CreateItem(inItemNo: Code[20]; Item2: Record Item; inDescription: Text[100]; inReplenishmentSystem: Enum "Replenishment System"; inCost: Decimal)
    begin
        Item.Init;
        Item."No." := Format(OffSetItemNo);
        Item.Insert;
        Item.Validate("Gen. Prod. Posting Group", Item2."Gen. Prod. Posting Group");
        Item.Validate("Base Unit of Measure", Item2."Base Unit of Measure");
        Item.Validate(Description, StrSubstNo(inDescription, Item.TableCaption));
        Item.Validate("Inventory Posting Group", Item2."Inventory Posting Group");
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Validate("Replenishment System", inReplenishmentSystem);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        if inReplenishmentSystem = Item."Replenishment System"::"Prod. Order" then begin
            Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
            Item."Production BOM No." := Item."No.";
            Item."Routing No." := Item."No.";
        end;
        if inReplenishmentSystem = Item."Replenishment System"::Purchase then begin
            Item.Validate("Vendor No.", '10000');
        end;
        Item.Validate("Standard Cost", inCost);
        Item.Validate("Unit Cost", inCost);
        Item.Modify;
    end;

    local procedure CreateWorkCenter(inWorkCenterNo: Code[10]; inWorkCenterName: Text[100]; inCostPrice: Decimal; inSubcontractor: code[20])
    var
        WorkCenter: Record "Work Center";
        WorkCenterGroup: Record "Work Center Group";
        ShopCalendar: Record "Shop Calendar";
        ShopCalLine: Record "Shop Calendar Working Days";
        CalcWorkCenterCalendar: Report "Calculate Work Center Calendar";
        WorkCenterUoM: Record "Capacity Unit of Measure";
        WorkShift: Record "Work Shift";
        GenProdPostGroup: Record "Gen. Product Posting Group";
    begin
        if not WorkCenterGroup.Get('Test') then begin
            WorkCenterGroup.Init();
            WorkCenterGroup.Code := 'TEST';
            WorkCenterGroup.Name := 'Test';
        end;
        if not WorkCenter.Get(inWorkCenterNo) then begin
            GenProdPostGroup.FindFirst();
            WorkCenter.Init();
            WorkCenter."No." := inWorkCenterNo;
            WorkCenter.Validate(Name, inWorkCenterName);
            WorkCenter."Work Center Group Code" := WorkCenterGroup.Code;
            WorkCenter.Validate("Direct Unit Cost", inCostPrice);
            WorkCenter."Subcontractor No." := inSubcontractor;
            if inSubcontractor <> '' then
                WorkCenter."Unit Cost Calculation" := WorkCenter."Unit Cost Calculation"::Units;
            WorkCenter."Shop Calendar Code" := 'Standard';
            WorkCenter.Capacity := 1;
            WorkCenter.Efficiency := 100;
            WorkCenter."Unit of Measure Code" := 'MINUTES';
            WorkCenter."Gen. Prod. Posting Group" := GenProdPostGroup.Code;
            WorkCenter.insert;

            if not WorkCenterUoM.Get(WorkCenter."Unit of Measure Code") then begin
                WorkCenterUoM.Init();
                WorkCenterUoM.Code := WorkCenter."Unit of Measure Code";
                WorkCenterUoM.Type := WorkCenterUoM.Type::Minutes;
                WorkCenterUoM.Insert();
            end;

            if not ShopCalendar.Get(WorkCenter."Shop Calendar Code") then begin
                ShopCalendar.Init();
                ShopCalendar.Code := WorkCenter."Shop Calendar Code";
                ShopCalendar.Description := '1 Shift';
                ShopCalendar.Insert();
                if not WorkShift.Get('1') then begin
                    WorkShift.Init();
                    WorkShift.Code := '1';
                    WorkShift.Insert();
                end;
                ShopCalLine.Init();
                ShopCalLine."Shop Calendar Code" := ShopCalendar.Code;
                ShopCalLine."Starting Time" := 070000T;
                ShopCalLine."Ending Time" := 160000T;
                ShopCalLine.Day := ShopCalLine.Day::Monday;
                ShopCalLine."Work Shift Code" := WorkShift.Code;
                ShopCalLine.Insert();
                ShopCalLine.Day := ShopCalLine.Day::Tuesday;
                ShopCalLine.Insert();
                ShopCalLine.Day := ShopCalLine.Day::Wednesday;
                ShopCalLine.Insert();
                ShopCalLine.Day := ShopCalLine.Day::Thursday;
                ShopCalLine.Insert();
                ShopCalLine.Day := ShopCalLine.Day::Friday;
                ShopCalLine.Insert();
            end;
        end;
        WorkCenter.SetRecFilter();
        CalcWorkCenterCalendar.SetTableView(WorkCenter);
    end;
}
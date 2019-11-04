//******************************************************************************************************
// Find recipe name
//******************************************************************************************************
FUNCTION FindRecName
	// Check if recipe name exists
	IF(RECIPE.DAT.RecipeNum > 0) THEN
		FOR idx:=0 TO RECIPE.DAT.RecipeNum - 1 DO
			IF(RECIPE.DAT.RecipeNames[idx] = RecipeName) THEN
				FindRecName := idx;
				RETURN;
			END_IF
		END_FOR;
	END_IF
	FindRecName := REC_DOES_NOT_EXIST;
END_FUNCTION

//******************************************************************************************************
// Create mappView data provider string
//******************************************************************************************************
FUNCTION WString2DataProvider
	brwcscpy(TargetString, ADR("{$"value$":$""));
	brwcscat(TargetString, SourceString);
	brwcscat(TargetString, ADR("$",$"text$":$""));	
	brwcscat(TargetString, SourceString);
	brwcscat(TargetString, ADR("$"}"));

	WString2DataProvider := TRUE;
END_FUNCTION

//******************************************************************************************************
// Create error																						
//******************************************************************************************************
FUNCTION CreateError
	RECIPE.ERR.No := No;
	RECIPE.ERR.State := State;
	RECIPE.ERR.Text := Text;
	CreateError := REC_ERROR;
END_FUNCTION

//******************************************************************************************************
// Create status meesage																						
//******************************************************************************************************
FUNCTION CreateMessage
	brwcscpy(ADR(tmpWStr1), Text);
	brwcscat(ADR(tmpWStr1), ADR(" "));
	brwcscat(ADR(tmpWStr1), RecipeName);
	brwcscat(ADR(tmpWStr1), ADR(" on web client ID "));
	VisuSlotIDStr := DINT_TO_WSTRING(VisuSlotID);
	brwcscat(ADR(tmpWStr1), ADR(VisuSlotIDStr));
	brwcscpy(TargetString, ADR(tmpWStr1));

	CreateMessage := TRUE;
END_FUNCTION

//******************************************************************************************************
// Working status																						
//******************************************************************************************************
FUNCTION WorkingStatus
	animation := animation+1;
	
	IF (animation = 80) THEN
		animation := 0;
	END_IF
	
	brsmemset(ADR(RECIPE.DAT.Status), 0, SIZEOF(RECIPE.DAT.Status));
	brwcscpy(ADR(RECIPE.DAT.Status), str);
	CASE(animation) OF
		0..19	: brwcscat(ADR(RECIPE.DAT.Status), ADR("/"));
		20..39	: brwcscat(ADR(RECIPE.DAT.Status), ADR("-"));
		40..59	: brwcscat(ADR(RECIPE.DAT.Status), ADR("\"));
		60..79	: brwcscat(ADR(RECIPE.DAT.Status), ADR("|"));
	END_CASE;
	WorkingStatus := animation;
END_FUNCTION

//******************************************************************************************************
// Fill new folder or directory name																	
//******************************************************************************************************
FUNCTION RemoveRecName
	// Remove name from recipe list
	IF(RecipeIndex < REC_MAX_NUM) THEN
		brsmemmove(ADR(RECIPE.DAT.RecipeNames[RecipeIndex]),ADR(RECIPE.DAT.RecipeNames[RecipeIndex+1]), (REC_MAX_NUM - RecipeIndex) * SIZEOF(RECIPE.DAT.RecipeNames[0]));
		brsmemmove(ADR(RECIPE.DAT.RecipeIDs[RecipeIndex]),ADR(RECIPE.DAT.RecipeIDs[RecipeIndex+1]), (REC_MAX_NUM - RecipeIndex) * SIZEOF(RECIPE.DAT.RecipeIDs[0]));
	END_IF
	brsmemset(ADR(RECIPE.DAT.RecipeNames[REC_MAX_NUM]), 0, SIZEOF(ADR(RECIPE.DAT.RecipeNames[0])));
	brsmemset(ADR(RECIPE.DAT.RecipeIDs[REC_MAX_NUM]), 0, SIZEOF(ADR(RECIPE.DAT.RecipeIDs[0])));
	RECIPE.DAT.RecipeNum := RECIPE.DAT.RecipeNum - 1;
	RemoveRecName := TRUE;
END_FUNCTION

//******************************************************************************************************
// Fill new folder or directory name																	
//******************************************************************************************************
FUNCTION InsertRecName
	// Set up start values for iteration																
	IF (RECIPE.DAT.RecipeNum <> 0) THEN 
		idy := RECIPE.DAT.RecipeNum - 1;
	END_IF
	idx := idy;
	
	// Start iteration	search																			
	WHILE (idy > 1) DO
		// Check current entry																			
		lSort := brwcscmp(ADR(new_name), ADR(RECIPE.DAT.RecipeNames[idy]));
		// Solve new search range																		
		IF (idy MOD 2 = 0) THEN
			idy := idy / 2;
		ELSE				
			idy := idy / 2 + 1;
		END_IF
		// New range is lower or higher than current													
		IF (lSort > 0) THEN
			idx := idx + idy;
			IF (idx > UINT_TO_INT(RECIPE.DAT.RecipeNum)) THEN
				idx := RECIPE.DAT.RecipeNum;  
			END_IF
		ELSE
			idx := idx - idy;
			IF (idx < 1) THEN
				idx := 1;
			END_IF
		END_IF		
	END_WHILE;
			
	// New entry is this, next or previous 																
	lSort := brwcscmp(ADR(new_name), ADR(RECIPE.DAT.RecipeNames[idx]));
	IF (lSort > 0 AND idx <> UINT_TO_INT(RECIPE.DAT.RecipeNum)) THEN 
		idx := idx +1;
	ELSIF (idx > 0) THEN
		lSort := brwcscmp(ADR(new_name), ADR(RECIPE.DAT.RecipeNames[idx-1]));
		IF (lSort < 0) THEN 
			idx := idx - 1;
		END_IF
	END_IF
	
	// Move all data entrys backwards and fill in new entry
	IF(idx < REC_MAX_NUM) THEN
		brsmemmove(ADR(RECIPE.DAT.RecipeNames[idx+1]),ADR(RECIPE.DAT.RecipeNames[idx]), (RECIPE.DAT.RecipeNum - idx) * SIZEOF(RECIPE.DAT.RecipeNames[1]));
		brsmemmove(ADR(RECIPE.DAT.RecipeIDs[idx+1]),ADR(RECIPE.DAT.RecipeIDs[idx]), (RECIPE.DAT.RecipeNum - idx) * SIZEOF(RECIPE.DAT.RecipeIDs[1]));
	END_IF
	brwcscpy(ADR(RECIPE.DAT.RecipeNames[idx]), ADR(new_name));
	brsstrcpy(ADR(RECIPE.DAT.RecipeIDs[idx]), ADR(new_id));
	
	RECIPE.DAT.RecipeNum := RECIPE.DAT.RecipeNum + 1;
	InsertRecName := idx;
END_FUNCTION

//******************************************************************************************************
// Is second string in first string																		
//******************************************************************************************************
FUNCTION IsInstrW	
	IF (brwcslen(string1) >= brwcslen(string2)) THEN
		FOR idx:=0 TO brwcslen(string1) - brwcslen(string2) DO
			IF (brwcsncmp(string1 + (2*idx), string2, brwcslen(string2)) = 0) THEN
				IsInstrW := TRUE;
				EXIT;
			END_IF
		END_FOR;
	END_IF
END_FUNCTION

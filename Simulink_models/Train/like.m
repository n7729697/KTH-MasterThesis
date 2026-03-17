
% Number of cells to insert after every 21 cells
insertionCount = 21;

% Number of cells before each insertion
insertionFrequency = 71;

% Calculate the number of insertions
numInsertions = floor(length(x) / insertionFrequency);

% Calculate the new length of the cell array with insertions
newLength = length(x) + numInsertions * insertionCount;

% Create a new cell array with the new length
xs = cell(newLength, 1);
ys = cell(newLength, 1);
% Copy elements from the original array and insert additional cells
index = 1;
insertIndex = 1;
for i = 1:length(x)
    xs(index) = x(i);
    ys(index) = y(i);
    index = index + 1;
    
    % Check if it's time to insert additional cells
    if mod(i, insertionFrequency) == 0 && insertIndex <= length(x_new_seq)
        xs(index:index+insertionCount-1) = x_new_seq(insertIndex:insertIndex+insertionCount-1);
        ys(index:index+insertionCount-1) = y_new_seq(insertIndex:insertIndex+insertionCount-1);
        index = index + insertionCount;
        insertIndex = insertIndex + 1;
    end
end



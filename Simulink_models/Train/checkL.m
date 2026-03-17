maxValues = zeros(3, size(sequence_lengths,2));
current=1;
for i=1:size(sequence_lengths,2)
    subsetSize = sequence_lengths(i);
    subset(1:subsetSize,1) = x_raw(current:min(current+subsetSize-1, numObs),4);
    subset(1:subsetSize,2:3) = x_raw(current:min(current+subsetSize-1, numObs),12:13);
    maxValues(1,i) = mean(subset(:,1));
    maxValues(2:3,i) = max(subset(:,2:3));
    current=current+subsetSize-1;
end
clear current subsetSize subset
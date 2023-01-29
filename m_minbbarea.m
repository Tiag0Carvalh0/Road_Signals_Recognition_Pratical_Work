function [areaBB] = m_minbbarea(m_bin)
    [B,~,N] = bwboundaries(m_bin);
    areaBB = NaN(N,1);
    for k=1:N
       boundary = B{k};
       [~,~,boxArea] = minboundrectla( boundary(:,2), boundary(:,1));  %x and y are flipped in images
       areaBB(k) = boxArea;  %filled area vs box area
    end
end
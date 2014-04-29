% GETSCORE
%   Computes the transition score between two rectangles
%   rect1 is one rectangle, rect2 is a series of rectangles
%   Score is computed as IoU + distance of 2 rectangles
function score = get_trans_score(rect1,rect2)
	IoU = getIoU(rect1, rect2);
	dist = getDist(rect1, rect2);
	
	score = IoU + dist;
end

function IoU =  getIoU(rect1,rect2)
	area1 = (rect1(3)-rect1(1)) * (rect1(4)-rect1(2));
	area2 = (rect2(:,3)-rect2(:,1)) .* (rect2(:,4)-rect2(:,2));
	xx1 = max(rect1(1), rect2(:,1));
	yy1 = max(rect1(2), rect2(:,2));
	xx2 = min(rect1(3), rect2(:,3));
	yy2 = min(rect1(4), rect2(:,4));
	
	w = max(0, xx2-xx1+1);
	h = max(0, yy2-yy1+1);
	inter = w .* h;
	
	IoU = inter ./ (area1+area2-inter);
end

function dist = getDist(rect1, rect2)
	c1 = [(rect1(1)+rect1(3))/2, (rect1(2)+rect1(4))/2];
	c2 = [(rect2(:,1)+rect2(:,3))/2, (rect2(:,2)+rect2(:,4))/2];
	d = repmat(c1, size(c2, 1), 1) - c2;
	d = abs(d(1)) + abs(d(2));
	dist = normpdf(d, 0, 10);
end


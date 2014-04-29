function evalDet(class)
	% evaluate the precision-recall of the detection result

	[~, X1, Y1, X2, Y2, ~] = textread([class '_groundTruth.txt'], '%s %d %d %d %d %d');
	[~, x1, y1, x2, y2, ~] = textread([class '_det.txt'], '%s %d %d %d %d %d');

	N = size(X1, 1);

	npos = 0; % number of positive samples
	tp = zeros(N,1); % true positives
	tp = zeros(N,1); % false positives

	for i = 1:N
		gt = [X1(i), Y1(i), X2(i), Y2(i)];
		det = [x1(i), y1(i), x2(i), y2(i)];
		if gt ~= [0 0 0 0]
			npos = npos+1;
		else
			continue;
		end
		a1 =  (gt(3)-gt(1)) * (gt(4)-gt(2));
		a2 =  (det(3)-det(1)) * (det(4)-det(2));
		xx1 = max(gt(1), det(:,1));
		yy1 = max(gt(2), det(:,2));
		xx2 = min(gt(3), det(:,3));
		yy2 = min(gt(4), det(:,4));
		w = max(0, xx2-xx1+1);
		h = max(0, yy2-yy1+1);
		inter = w * h;
		o = inter / (a1+a2-inter);
		if o >= 0.5
			tp(i) = 1;
		else
			fp(i) = 1;
		end
	end
	tp = cumsum(tp);
	fp = cumsum(fp);
	rec = tp / npos;
	prec = tp ./ (fp + tp);
	
	ap = 0;
	for t = 0:0.1:1
		p = max(prec(rec>=t));
		if isempty(p)
			p = 0;
		end
		ap = ap+p/11;
	end
	plot(rec,prec,'-');
    grid;
    xlabel 'recall'
    ylabel 'precision'
    title(sprintf('class: %s, AP = %.3f',class,ap));
end
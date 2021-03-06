function [self] = Southampton2onerm()
self.www     = 'http://www.southampton.ac.uk/~cpd/anovas/datasets/Doncaster&Davey%20-%20Model%206_3%20Two%20factor%20model%20with%20RM%20on%20one%20cross%20factor.txt';
self.Y       = [-3.8558, 4.4076, -4.1752, 1.4913, 5.9699, 5.2141, 9.1467, 5.8209, 9.4082, 6.0296, 15.3014, 12.1900, 6.9754, 14.3012, 10.4266, 2.3707, 19.1834, 18.3855, 23.3385, 21.9134, 16.4482, 11.6765, 17.9727, 15.1760]';
self.A       = [1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3]';
self.B       = [1, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 1, 2, 2, 2, 2]';
subj         = [1, 2, 3, 4, 1, 2, 3, 4];
self.SUBJ    = [subj, subj+10, subj+20]';
self.z       = [48.17, 0.01, 5.41];
self.df      = {[2,9], [1,9], [2,9]};
self.p       = {'<0.001', 0.915, 0.029};
end
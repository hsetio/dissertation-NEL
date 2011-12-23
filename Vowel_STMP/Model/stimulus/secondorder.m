function [freqs, gain] = secondorder(rfreq, bw, lofreq, hifreq, freqint)% SECONDORDER - returns the complex gain of a second order system with% resonant frequency rfreq and -3 dB bandwidth bw over the frequency range% [lofreq: freqint: hifreq]. It is the user's responsibility to make sure% the units are consistent, but the routine assumes that frequencies are% specified in radians.%   [freqs, gain] = secondorder(rfreq, bw, lofr, hifr, freqint)% The poles of the transfer function are A�jw0 where%    rfreq = sqrt(w0^2 - A^2)%    bw = 2*A*w0/rfreq% Calculate these in a two-step approximationw0 = rfreq; j1 = 1; err = 1;while err>1e-5 & j1<10	A = bw*rfreq/(2*w0);	w0old = w0;	w0 = sqrt(rfreq^2+A^2);	err = abs(w0-w0old)/w0; j1 = j1 + 1;end%fprintf('For res.freq=%g and BW=%g rad, w0=%g and A=%g,\n with relative error %g.\n', ...%       rfreq, bw, w0, A, err)plpole = A + j*w0; mnpole = A - j*w0;freqs = [lofreq:freqint:hifreq]';gain = zeros(length(freqs),1);for j1=1:length(freqs)   gain(j1) = (A^2+w0^2)/(w0^2+A^2-freqs(j1)^2+j*2*A*freqs(j1));endreturn
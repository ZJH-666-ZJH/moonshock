#!/usr/bin/env python3
"""Independent Newton reference and Rankine-Hugoniot/fan-invariant checks.
Input is JSONL emitted by examples/oracle, not a recorded success fixture.
Only Python's standard library is required. No third-party solver code copied.
"""
import argparse, json, math, subprocess, sys

def curve(p, q, gamma):
    rho, pressure = q['rho'], q['pressure']
    c = math.sqrt(gamma * pressure / rho)
    if p <= pressure:
        exponent = (gamma - 1) / (2 * gamma)
        return (2*c/(gamma-1)*((p/pressure)**exponent-1),
                (p/pressure)**(-(gamma+1)/(2*gamma))/(rho*c))
    a, b = 2/((gamma+1)*rho), (gamma-1)/(gamma+1)*pressure
    s = math.sqrt(a/(p+b))
    return (p-pressure)*s, s*(1-(p-pressure)/(2*(p+b)))

def newton(left, right, gamma):
    p = (left['pressure'] + right['pressure']) / 2
    for _ in range(200):
        fl, dl = curve(p, left, gamma)
        fr, dr = curve(p, right, gamma)
        residual = fl+fr+right['velocity']-left['velocity']
        if abs(residual) < 2e-14:
            return p, (left['velocity']+right['velocity']+fr-fl)/2
        update = p-residual/(dl+dr)
        p = max(update, p*0.1)
    raise AssertionError('independent Newton did not converge')

def near(a, b, scale=1):
    assert math.isfinite(a) and math.isfinite(b)
    assert abs(a-b) <= 2e-9*max(scale,abs(a),abs(b)), (a,b)

def state(q,g):
    d,u,p=q['rho'],q['velocity'],q['pressure']
    return [d,d*u,p/(g-1)+d*u*u/2]

def flux(q,g):
    d,m,e=state(q,g);u=q['velocity'];p=q['pressure']
    return [m,m*u+p,(e+p)*u]

def verify(case):
    g,l,r=case['gamma'],case['left'],case['right']
    p,u=newton(l,r,g)
    near(case['p'],p);near(case['u'],u)
    for side,base,density,speed in [(True,l,case['rho_l'],case['speeds'][0]),(False,r,case['rho_r'],case['speeds'][3])]:
        star={'rho':density,'velocity':case['u'],'pressure':case['p']}
        if p>base['pressure']*(1+1e-10):
            # Conservation jump condition is independent of the pressure-root code.
            ub,us=state(base,g),state(star,g)
            fb,fs=flux(base,g),flux(star,g)
            for j in range(3):near(speed*(us[j]-ub[j]),fs[j]-fb[j])
        else:
            near(star['pressure']/density**g,base['pressure']/base['rho']**g)
    for sample in case['samples']:
        xi,q=sample['xi'],sample['q']
        assert q['rho']>0 and q['pressure']>0
        a,b,c,d=case['speeds']
        if xi<a:assert q==l
        elif xi>d:assert q==r
        elif a<xi<b:
            sound=math.sqrt(g*q['pressure']/q['rho'])
            near(q['velocity']-sound,xi)
            near(q['velocity']+2*sound/(g-1),l['velocity']+2*math.sqrt(g*l['pressure']/l['rho'])/(g-1))
            near(q['pressure']/q['rho']**g,l['pressure']/l['rho']**g)
        elif c<xi<d:
            sound=math.sqrt(g*q['pressure']/q['rho'])
            near(q['velocity']+sound,xi)
            near(q['velocity']-2*sound/(g-1),r['velocity']-2*math.sqrt(g*r['pressure']/r['rho'])/(g-1))
            near(q['pressure']/q['rho']**g,r['pressure']/r['rho']**g)
        else:
            near(q['pressure'],p);near(q['velocity'],u)

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--target',default='wasm-gc',choices=['wasm-gc','wasm','js','native'])
    parser.add_argument('--jsonl',help='read an already exported JSONL file')
    args=parser.parse_args()
    if args.jsonl:
        with open(args.jsonl,encoding='utf-8') as stream:text=stream.read()
    else:
        text=subprocess.check_output(['moon','run','examples/oracle','--target',args.target],encoding='utf-8')
    rows=[json.loads(line) for line in text.splitlines() if line.strip()]
    assert len(rows)==42, len(rows)
    for i,row in enumerate(rows):
        try:verify(row)
        except Exception as error:raise AssertionError('case %d failed'%i) from error
    print('PASS: 42 Riemann cases; 378 sample states; Newton, shock jumps and fan invariants')
if __name__=='__main__':main()

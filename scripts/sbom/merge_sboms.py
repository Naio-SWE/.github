#!/usr/bin/env python3
"""
Merge Python and JavaScript SBOMs into a single CycloneDX SBOM.
"""

import json
import glob
import os


def load_js_license_map():
    """Load license data from license-checker JSON outputs."""
    js_license_map = {}
    for js_lic_file in glob.glob('/tmp/js-licenses-*.json'):
        try:
            with open(js_lic_file) as f:
                lic_data = json.load(f)
                for pkg_name, pkg_info in lic_data.items():
                    base_name = pkg_name.split('@')[0] if '@' in pkg_name else pkg_name
                    js_license_map[base_name] = pkg_info.get('licenses', 'UNKNOWN')
        except (FileNotFoundError, json.JSONDecodeError):
            pass
    return js_license_map


def load_python_components():
    """Load filtered Python components."""
    components = []
    if os.path.exists('/tmp/python-filtered.json'):
        with open('/tmp/python-filtered.json') as f:
            sbom = json.load(f)
            components.extend(sbom.get('components', []))
    return components


def load_js_components(js_license_map):
    """Load JavaScript components and enhance with license data."""
    components = []
    for js_sbom in glob.glob('/tmp/js-sbom-*.json'):
        with open(js_sbom) as f:
            sbom = json.load(f)
            for comp in sbom.get('components', []):
                # Enhance with license-checker data if missing
                if not comp.get('licenses'):
                    purl = comp.get('purl', '')
                    if purl.startswith('pkg:npm/'):
                        pkg_name = purl.split('pkg:npm/')[1].split('@')[0]
                        if pkg_name in js_license_map:
                            lic = js_license_map[pkg_name]
                            if lic and lic != 'UNKNOWN':
                                comp['licenses'] = [{
                                    'license': {
                                        'id': lic
                                    }
                                }]
                components.append(comp)
    return components


def deduplicate_components(components):
    """Remove duplicate components based on purl."""
    seen_purls = set()
    unique = []
    for comp in components:
        purl = comp.get('purl', '')
        if purl and purl not in seen_purls:
            seen_purls.add(purl)
            unique.append(comp)
        elif not purl:
            unique.append(comp)
    return unique


def create_combined_sbom(components):
    """Create a CycloneDX SBOM structure."""
    return {
        'bomFormat': 'CycloneDX',
        'specVersion': '1.4',
        'version': 1,
        'components': components
    }


def print_statistics(components):
    """Print SBOM statistics."""
    total = len(components)
    python_count = len([c for c in components if c.get('purl', '').startswith('pkg:pypi/')])
    npm_count = len([c for c in components if c.get('purl', '').startswith('pkg:npm/')])
    with_lic = len([c for c in components if c.get('licenses')])
    pct = 100 * with_lic // total if total > 0 else 0
    
    print(f"\n✅ Combined SBOM:")
    print(f"   Python packages:     {python_count}")
    print(f"   JavaScript packages: {npm_count}")
    print(f"   Total:               {total}")
    print(f"   With licenses:       {with_lic} ({pct}%)")


def main():
    output_file = 'sboms/sbom.json'
    
    # Load all components
    js_license_map = load_js_license_map()
    python_components = load_python_components()
    js_components = load_js_components(js_license_map)
    
    # Combine and deduplicate
    all_components = python_components + js_components
    unique_components = deduplicate_components(all_components)
    
    # Create and save SBOM
    sbom = create_combined_sbom(unique_components)
    with open(output_file, 'w') as f:
        json.dump(sbom, f, indent=2)
    
    print_statistics(unique_components)


if __name__ == '__main__':
    main()

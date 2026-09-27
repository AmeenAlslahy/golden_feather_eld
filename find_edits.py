import json

transcript_path = r"C:\Users\Owner\.gemini\antigravity-ide\brain\e642fd42-5ae2-4e30-8873-be92d5cee50e\.system_generated\logs\transcript.jsonl"

with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            entry = json.loads(line)
            if 'tool_calls' in entry:
                for tc in entry['tool_calls']:
                    if tc.get('name') in ['replace_file_content', 'multi_replace_file_content', 'write_to_file']:
                        args = tc.get('arguments', {})
                        target_file = args.get('TargetFile', '')
                        if 'features' in target_file and 'presentation' in target_file:
                            print(f"File edited: {target_file}")
                            # Print a snippet of what was changed
                            if 'CodeContent' in args:
                                print("WROTE FILE")
                            elif 'ReplacementContent' in args:
                                print(f"REPLACED: {args['ReplacementContent'][:100]}...")
                            elif 'ReplacementChunks' in args:
                                print("MULTI_REPLACE")
                                
        except json.JSONDecodeError:
            pass

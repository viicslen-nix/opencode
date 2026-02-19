{
  lib,
  config,
  ...
}:
with lib; let
  name = "opencode";
  namespace = "programs";

  cfg = config.modules.${namespace}.${name};
in {
  # Define the configuration options for this module
  options.modules.${namespace}.${name} = {
    enable = mkEnableOption (mdDoc name);

    model = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = mdDoc "The model to use for opencode.";
    };

    small_model = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = mdDoc "The small model to use for opencode.";
    };
  };

  # Apply configuration if the module is enabled
  config.programs.opencode = mkIf cfg.enable {
    enable = true;
    enableMcpIntegration = true;

    # Configure available agents from local markdown files
    agents = {
      ask = ./agents/ask.md;
      debug = ./agents/debug.md;
      review = ./agents/review.md;
      security = ./agents/security.md;
      documentation = ./agents/documentation.md;
      assessment-review = ./agents/assessment-review.md;
    };

    # Configure available skills
    skills = {
      browser-automation = ./skills/browser-automation.md;
    };

    # Main Opencode settings
    settings = {
      autoshare = false;
      # Use configured models if provided
      model = mkIf (cfg.model != null) cfg.model;
      small_model = mkIf (cfg.small_model != null) cfg.small_model;

      # File patterns to ignore
      watcher.ignore = [
        "**/node_modules/**"
        "**/.git/**"
        "**/.hg/**"
        "**/.svn/**"
        "**/.DS_Store"
        "**/dist/**"
        "**/build/**"
        "**/.next/**"
        "**/out/**"
        "**/vendor/**"
      ];

      # Installed plugins
      plugin = [
        "oh-my-opencode@latest"
        "opencode-pty@latest"
        "opencode-antigravity-auth@latest"
        "@tarquinen/opencode-dcp@latest"
        "opencode-websearch-cited@latest"
        "@mohak34/opencode-notifier@latest"
        "@zenobius/opencode-skillful@latest"
        "@nick-vi/opencode-type-inject@latest"
        "@different-ai/opencode-browser@latest"
      ];

      # Model Context Protocol (MCP) servers
      mcp = {
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
        };
        gh_grep = {
          type = "remote";
          url = "https://mcp.grep.app";
        };
      };

      # AI Provider configurations
      provider = {
        anthropic.options.setCacheKey = true;
        google.models = {
          antigravity-gemini-3-pro = {
            name = "Gemini 3 Pro (Antigravity)";
            limit = {
              context = 1048576;
              output = 65535;
            };
            modalities = {
              input = ["text" "image" "pdf"];
              output = ["text"];
            };
            variants = {
              low = {
                thinkingLevel = "low";
              };
              high = {
                thinkingLevel = "high";
              };
            };
          };
          antigravity-gemini-3-flash = {
            name = "Gemini 3 Flash (Antigravity)";
            limit = {
              context = 1048576;
              output = 65536;
            };
            modalities = {
              input = ["text" "image" "pdf"];
              output = ["text"];
            };
            variants = {
              minimal = {
                thinkingLevel = "minimal";
              };
              low = {
                thinkingLevel = "low";
              };
              medium = {
                thinkingLevel = "medium";
              };
              high = {
                thinkingLevel = "high";
              };
            };
          };
          antigravity-claude-sonnet-4-5 = {
            name = "Claude Sonnet 4.5 (Antigravity)";
            limit = {
              context = 200000;
              output = 64000;
            };
            modalities = {
              input = ["text" "image" "pdf"];
              output = ["text"];
            };
          };
          antigravity-claude-sonnet-4-5-thinking = {
            name = "Claude Sonnet 4.5 Thinking (Antigravity)";
            limit = {
              context = 200000;
              output = 64000;
            };
            modalities = {
              input = ["text" "image" "pdf"];
              output = ["text"];
            };
            variants = {
              low = {
                thinkingConfig = {
                  thinkingBudget = 8192;
                };
              };
              max = {
                thinkingConfig = {
                  thinkingBudget = 32768;
                };
              };
            };
          };
          antigravity-claude-opus-4-5-thinking = {
            name = "Claude Opus 4.5 Thinking (Antigravity)";
            limit = {
              context = 200000;
              output = 64000;
            };
            modalities = {
              input = ["text" "image" "pdf"];
              output = ["text"];
            };
            variants = {
              low = {
                thinkingConfig = {
                  thinkingBudget = 8192;
                };
              };
              max = {
                thinkingConfig = {
                  thinkingBudget = 32768;
                };
              };
            };
          };
          gemini-2_5-flash = {
            name = "Gemini 2.5 Flash (Gemini CLI)";
            limit = {
              context = 1048576;
              output = 65536;
            };
            modalities = {
              input = ["text" "image" "pdf"];
              output = ["text"];
            };
          };
          gemini-2_5-pro = {
            name = "Gemini 2.5 Pro (Gemini CLI)";
            limit = {
              context = 1048576;
              output = 65536;
            };
            modalities = {
              input = ["text" "image" "pdf"];
              output = ["text"];
            };
          };
          gemini-3-flash-preview = {
            name = "Gemini 3 Flash Preview (Gemini CLI)";
            limit = {
              context = 1048576;
              output = 65536;
            };
            modalities = {
              input = ["text" "image" "pdf"];
              output = ["text"];
            };
          };
          gemini-3-pro-preview = {
            name = "Gemini 3 Pro Preview (Gemini CLI)";
            limit = {
              context = 1048576;
              output = 65535;
            };
            modalities = {
              input = ["text" "image" "pdf"];
              output = ["text"];
            };
          };
        };
      };
    };
    rules = ''
      ## Output Control

      CRITICAL: Keep responses concise and actionable. Minimize verbosity.

      ### Build Mode
      When implementing code changes or building features:
      - Provide brief confirmation when tasks complete successfully (e.g., "Done" or "Created X, updated Y")
      - Do NOT generate detailed change reports unless explicitly requested
      - Do NOT create report files or summaries automatically
      - Do NOT list all modifications made - the user can see the changes
      - Only provide detailed explanations when errors occur or when asked

      ### Plan Mode
      When creating or iterating on plans:
      - Present plans concisely with clear action items
      - After incorporating feedback, acknowledge changes briefly (e.g., "Updated plan with X")
      - Do NOT output diffs of plan changes
      - Do NOT include code snippets unless specifically requested
      - Do NOT explain every detail of what will change - just update the plan
      - Keep iterations minimal - revise and move forward

      ### General Communication
      - Answer questions directly without preamble
      - Confirm completions in one line when possible
      - Reserve detailed explanations for errors or explicit requests
      - Focus on what the user needs to know, not what you did

      ## External File Loading

      CRITICAL: When you encounter a file reference (e.g., @rules/general.md), use your Read tool to load it on a need-to-know basis. They're relevant to the SPECIFIC task at hand.

      Instructions:

      - Do NOT preemptively load all references - use lazy loading based on actual need
      - When loaded, treat content as mandatory instructions that override defaults
      - Follow references recursively when needed

      ## Tools

      - When you need to search docs, use `context7` tools.
      - If you are unsure how to do something, use `gh_grep` to search code examples from GitHub.
      - When you need to ask questions to the user, use the `question` tool.
    '';
  };
}
